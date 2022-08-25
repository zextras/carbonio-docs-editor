import argparse
import json
from typing import List

import requests

def _update_service_sidecar_config(service_name: str, parameter: str, service_id: str) -> dict:

    with open(f"/etc/zextras/service-discover/templates/{service_name}-template.hcl", "r") as sidecar_config:
        content = sidecar_config.read()
        content = content.replace("$METADATA_KEY", parameter)
        content = content.replace("$METADATA_VALUE", service_id)

    with open(f"/etc/zextras/service-discover/{service_name}.hcl", "w") as sidecar_config:
        sidecar_config.write(content)

    print(f'/etc/zextras/service-discover/{service_name}.hcl sidecar configuration file correctly updated')


def _generate_service_resolver_config(service_name: str, parameter: str, service_ids: List[str]) -> dict:

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


def _generate_service_router_config(service_name: str, parameter: str, service_ids: List[str]) -> dict:

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


def _write_config_to_file(absolute_path: str, filename: str, config: dict) -> None:

    if not absolute_path:
        absolute_path = "./"

    config_json = json.dumps(config, indent=2)
    with open(f"{absolute_path}/{filename}.json", "w") as config_file:
        config_file.write(config_json)

    print(f'{absolute_path}/{filename}.json configuration file correctly generated')


parser = argparse.ArgumentParser(description="""Generate the service-resolver
 and the service-router configuration file adding a new instance to the
 specified service""")

parser.add_argument(
        "-s",
        "--service-name",
        help="Name of the service to add the instance",
        required=True
        )
parser.add_argument(
        "-p",
        "--parameter",
        help="Name of the query parameter used to identify an instance",
        required=True
        )
parser.add_argument(
        "-i",
        "--service-id",
        help="Id of the new instance to add",
        required=True
        )
parser.add_argument(
    "-d",
    "--destination",
    help="Full path where to write the generated configs",
    required=False
)

args = parser.parse_args()

try:
    response = requests.get(f'http://127.0.0.1:8500/v1/catalog/service/{args.service_name}')
    response.raise_for_status()
except requests.exceptions.ConnectionError:
    exit("Unable to connect to the service-discover: http://127.0.0.1:8500/v1/catalog/service/")
except requests.exceptions.RequestException as exception:
    if exception.response.status_code != 404:
        exit("Unable to connect to the service-discover: http://127.0.0.1:8500/v1/catalog/service/")

subsets = []
if response.ok:

    try:
        jsonResponse = json.loads(response.text)
    except (TypeError, json.JSONDecodeError) as exception:
        exit(f"Unable to parse the json service-discover response: {exception}")

    for serviceInstance in jsonResponse:
        if 'ServiceMeta' in serviceInstance and args.parameter in serviceInstance['ServiceMeta']:
            subsets.append(serviceInstance['ServiceMeta'][args.parameter])

subsets.append(args.service_id)

resolverConf = _generate_service_resolver_config(args.service_name, args.parameter, subsets)
routerConf = _generate_service_router_config(args.service_name, args.parameter, subsets)

_write_config_to_file(args.destination, "service-resolver", resolverConf)
_write_config_to_file(args.destination, "service-router", routerConf)
_update_service_sidecar_config(args.service_name, args.parameter, args.service_id)
