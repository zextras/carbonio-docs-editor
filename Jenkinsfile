// SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@1.3.1',
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
            label 'base'
        }
    }

    environment {
        NODE_MAJOR = '20'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        skipDefaultCheckout()
        timeout(time: 1, unit: 'HOURS')
    }


    stages {
        stage('Setup') {
            steps {
                checkout scm
                script {
                    gitMetadata()
                }
            }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'artifactory-jenkins-gradle-properties-splitted',
                        passwordVariable: 'SECRET',
                        usernameVariable: 'USERNAME'
                    )
                ]) {
                    script {
                        env.REPO_ENV = env.GIT_TAG ? 'rc' : 'devel'
                    }

                    buildStage([
                        prepare: true,
                        overrides: [
                            'ubuntu-jammy': [
                                preBuildScript: '''
                                    echo "machine zextras.jfrog.io" >> auth.conf
                                    echo "login $USERNAME" >> auth.conf
                                    echo "password $SECRET" >> auth.conf
                                    mv auth.conf /etc/apt
                                    echo "deb [trusted=yes] https://zextras.jfrog.io/artifactory/ubuntu-''' + env.REPO_ENV + ''' jammy main" > zextras.list
                                    echo "deb [trusted=yes] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > nodesource.list
                                    mv *.list /etc/apt/sources.list.d/
                                    apt-get update && apt-get install -y nodejs
                                '''
                            ],
                            'ubuntu-noble': [
                                preBuildScript: '''
                                    echo "machine zextras.jfrog.io" >> auth.conf
                                    echo "login $USERNAME" >> auth.conf
                                    echo "password $SECRET" >> auth.conf
                                    mv auth.conf /etc/apt
                                    echo "deb [trusted=yes] https://zextras.jfrog.io/artifactory/ubuntu-''' + env.REPO_ENV + ''' noble main" > zextras.list
                                    echo "deb [trusted=yes] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > nodesource.list
                                    mv *.list /etc/apt/sources.list.d/
                                    apt-get update && apt-get install -y nodejs
                                '''
                            ],
                        ]
                    ])
                }
            }
        }

        stage('Upload artifacts')
        {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage([
                    packages: yapHelper.resolvePackageNames()
                ])
            }
        }
    }
}
