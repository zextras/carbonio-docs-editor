import argparse
import json

from typing import List

import requests
import socket
import uuid


def _generate_service_config_from_template(
    service_name: str,
    parameter: str,
    service_id: str
) -> None:

    with open(
        f"/etc/zextras/service-discover/templates/{service_name}-template.hcl",
        "r"
    ) as sidecar_config:
        content: str = sidecar_config.read()
        content = content.replace("$METADATA_KEY", parameter)
        content = content.replace("$METADATA_VALUE", service_id)

    with open(
        f"/etc/zextras/service-discover/{service_name}.hcl",
        "w"
    ) as sidecar_config:
        sidecar_config.write(content)

    print(
        f"/etc/zextras/service-discover/{service_name}.hcl sidecar"
        f"configuration file correctly updated"
    )


def _generate_service_resolver_config(
    service_name: str,
    parameter: str,
    service_ids: List[str]
) -> dict:

    service_resolver_config: dict = {
        "Kind": "service-resolver",
        "Name": service_name
    }

    subsets: dict = {}
    for service_id in service_ids:
        filter: dict = {
                "Filter": f'Service.Meta.{parameter} == \"{service_id}\"'
            }
        subsets[service_id] = filter

    service_resolver_config["Subsets"] = subsets
    return service_resolver_config


def _generate_service_router_config(
    service_name: str,
    parameter: str,
    service_ids: List[str]
) -> dict:

    service_router_config: dict = {
        "Kind": "service-router",
        "Name": service_name,
        "Routes": []
    }

    for service_id in service_ids:
        route: dict = {
            "Match": {
                "HTTP": {
                    "QueryParam": [
                        {
                            "Name": parameter,
                            "Exact": service_id
                        }
                    ]
                }
            },
            "Destination": {
                "Service": service_name,
                "ServiceSubset": service_id
            }
        }

        service_router_config['Routes'].append(route)

    return service_router_config


def _write_config_to_file(
    absolute_path: str,
    filename: str,
    config: dict
) -> None:

    config_json: str = json.dumps(config, indent=2)
    with open(f"{absolute_path}/{filename}.json", "w") as config_file:
        config_file.write(config_json)

    print(
        f"{absolute_path}/{filename}.json configuration file correctly "
        f"generated"
    )


# Start python script
root_parser: argparse.ArgumentParser = argparse.ArgumentParser(description="""
    Generate the service-resolver and the service-router configuration files
    adding a new instance to the specified service. Generate the
    service configuration for consul using a template placed in
    /etc/zextras/service-discover/template/
    """)

# Subparser for the subcommands
subparsers = root_parser.add_subparsers(dest="subcommand")

# Sub-command 'add'
add_parser = subparsers.add_parser("add", help="""
    The 'add' subcommand generates the service-resolver, the service-router 
    and the service hcl configuration files
    """)
add_parser.add_argument(
    "-s",
    "--service-name",
    help="Name of the service to add the instance (e.g. carbonio-example)",
    required=True,
    type=str
)
add_parser.add_argument(
    "-p",
    "--parameter",
    help="Name of the query parameter used to identify an instance in consul",
    required=False,
    nargs="?",
    default="service_id",
    type=str
)
add_parser.add_argument(
    "-d",
    "--destination",
    help="Full path where to write the generated configs",
    required=True,
    type=str
)


# Sub-command 'regenerate'
regenerate_parser = subparsers.add_parser("regenerate", help="""
    The 'regenerate' subcommand should be used when a service instance is 
    removed from a node and it should be removed also from the routing 
    configurations. 
    It regenerates the service-resolver and service-router configs containing
    ids of all the instances already registered without the deleted one
    """)
regenerate_parser.add_argument(
    "-s",
    "--service-name",
    help="Name of the service to add the instance (e.g. carbonio-example)",
    required=True,
    type=str
    )
regenerate_parser.add_argument(
    "-p",
    "--parameter",
    help="Name of the query parameter used to identify an instance in consul",
    required=False,
    nargs="?",
    default="service_id",
    type=str
    )
regenerate_parser.add_argument(
    "-d",
    "--destination",
    help="Full path where to write the generated configs",
    required=True,
    type=str
    )

args: argparse.Namespace = root_parser.parse_args()

# Service ids fetching
try:
    response: requests.models.Response = requests.get(
        f"http://127.0.0.1:8500/v1/catalog/service/{args.service_name}"
    )
    response.raise_for_status()
except requests.exceptions.ConnectionError:
    exit(
        f"Unable to connect to the service-discover: "
        f"http://127.0.0.1:8500/v1/catalog/service/"
    )
except requests.exceptions.RequestException as exception:
    if exception.response.status_code != 404:
        exit(
            f"Unable to connect to the service-discover: "
            f"http://127.0.0.1:8500/v1/catalog/service/"
        )

service_ids: List[str] = []
service_id: str = None

if response.ok:

    try:
        json_response: str = json.loads(response.text)
    except (TypeError, json.JSONDecodeError) as exception:
        exit(f"Unable to parse the json service-discover response: {exception}")

    # The ip address is the only way to identify the id of the service instance
    # installed on this node (if there is/was one).
    ip_address: str = socket.gethostbyname(socket.gethostname())

    # Loop through all the instances to collect their service_id. If this server
    # has already a service instance registered on consul, then its service_id
    # is saved and reused to generate the configs instead of generating a new
    # id. This flow prevents conflicts between ids and avoid to store
    # unnecessary ids on consul
    for instance in json_response:
        if 'ServiceMeta' in instance and args.parameter in instance['ServiceMeta']:
            service_ids.append(instance['ServiceMeta'][args.parameter])
            if 'Address' in instance and ip_address in instance['Address']:
                service_id = instance['ServiceMeta'][args.parameter]


if args.subcommand == "add":
    # Consul does not have a registered service instance for this node (server).
    # So it is the first time the service is installed in this node, then it
    # generates the service_id saving it in the service_ids list.
    if not service_id:
        service_id = str(uuid.uuid4())
        service_ids.append(service_id)

    # Generate the service-resolver and service-router configs containing ids
    # of all the instances already registered plus the one installed/updated.
    resolver_conf: dict = _generate_service_resolver_config(
        args.service_name,
        args.parameter,
        service_ids
    )
    router_conf: dict = _generate_service_router_config(
        args.service_name,
        args.parameter,
        service_ids
    )

    _write_config_to_file(
        args.destination,
        "service-resolver",
        resolver_conf
    )
    _write_config_to_file(
        args.destination,
        "service-router",
        router_conf
    )

    # Generate the service config (hcl). This should be generated each time a
    # service instance is installed or updated
    _generate_service_config_from_template(
        args.service_name,
        args.parameter,
        service_id
    )

elif args.subcommand == "regenerate":
    # The 'regenerate' subcommand is called when the sysadmin wants to
    # regenerate the consul routing configurations after the deletion of an
    # instance.

    # Generate the service-resolver and service-router configs containing
    # ids of all the instances already registered without the deleted one.
    resolver_conf: dict = _generate_service_resolver_config(
        args.service_name,
        args.parameter,
        service_ids
    )
    router_conf: dict = _generate_service_router_config(
        args.service_name,
        args.parameter,
        service_ids
    )

    _write_config_to_file(
        args.destination,
        "service-resolver",
        resolver_conf
    )
    _write_config_to_file(
        args.destination,
        "service-router",
        router_conf
    )
else:
    root_parser.print_help()
