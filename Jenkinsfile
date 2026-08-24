// SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@v4.8.1',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)

properties(defaultPipelineProperties())

pipeline {
    agent {
        node {
            label 'zextras-v1'
        }
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
        skipDefaultCheckout()
        timeout(time: 1, unit: 'HOURS')
    }


    stages {
        stage('Setup') {
            steps {
                checkout scm
                gitMetadata()
            }
        }

        stage('Publish docker image') {
            steps {
                dockerStage([
                    dockerfile: 'docker/docs-editor-sidecar/Dockerfile',
                    imageName: 'registry.dev.zextras.com/dev/carbonio-docs-editor-sidecar',
                    ocLabels: [
                        title: 'Carbonio Docs Editor Sidecar',
                    ]
                ])
            }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                buildStage([
                    prepare: true,
                    addCarbonioRepos: true,
                    prepareFlags: '--repo \'name=nodesource,url=https://deb.nodesource.com/node_20.x,suite=nodistro,components=main,distros=ubuntu\' --repo \'name=nodesource,url=https://rpm.nodesource.com/pub_20.x/nodistro/nodejs/x86_64,format=rpm,distros=rocky\'',
                    buildFlags: '--repo \'name=nodesource,url=https://deb.nodesource.com/node_20.x,suite=nodistro,components=main,distros=ubuntu\' --repo \'name=nodesource,url=https://rpm.nodesource.com/pub_20.x/nodistro/nodejs/x86_64,format=rpm,distros=rocky\'',
                    overrides: [
                        'rocky-8': [
                            branchBuildDirs: [
                                devel: [ 'rpm-only', '.' ]
                            ]
                        ],
                        'rocky-9': [
                            branchBuildDirs: [
                                devel: [ 'rpm-only', '.' ]
                            ]
                        ],
                    ]
                ])
            }
        }

        stage('Upload artifacts')
        {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage()
            }
        }
    }
}
