pipeline {
    parameters {
        booleanParam defaultValue: false,
        description: 'Whether to upload the packages in playground repositories',
        name: 'PLAYGROUND'
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 1, unit: 'HOURS')
    }
    agent {
        node {
            label 'base-agent-v1'
        }
    }
    environment {
        NETWORK_OPTS = '--network ci_agent'
    }
    stages {
        stage('Checkout & Stash') {
            agent {
                node {
                    label 'base-agent-v1'
                }
            }
            steps {
                checkout scm
                dir('theme') {
                    checkout([$class: 'GitSCM',
                          branches: [[name: '*/carbonio']],
                          userRemoteConfigs: [[credentialsId: 'tarsier_bot-ssh-key',
                                               name: 'zimbra-docs-branding',
                                               refspec: "refs/heads/carbonio",
                                               url: 'git@bitbucket.org:zextras/zimbra-docs-branding.git'
                                             ]]
                         ])
                }
                stash includes: '**', name: 'project'
            }
        }
        stage('Packaging') {
            parallel {
                stage('Ubuntu 20') {
                    agent {
                        node {
                            label 'pacur-agent-ubuntu-20.04-v1'
                        }
                    }
                    steps {
                        unstash 'project'
                        withCredentials([usernamePassword(credentialsId: 'artifactory-jenkins-gradle-properties-splitted', 
                            passwordVariable: 'SECRET',
                            usernameVariable: 'USERNAME')]) {
                                sh 'echo "machine zextras.jfrog.io" >> auth.conf'
                                sh 'echo "login $USERNAME" >> auth.conf'
                                sh 'echo "password $SECRET" >> auth.conf'
                                sh 'sudo mv auth.conf /etc/apt'
                        }
                        sh '''
sudo echo "deb https://zextras.jfrog.io/artifactory/ubuntu-playground focal main" > zextras.list
sudo mv zextras.list /etc/apt/sources.list.d/
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52FD40243E584A21
'''
                        sh 'sudo mv theme /tmp'
                        sh 'sudo pacur build ubuntu-focal .'
                        stash includes: 'artifacts/',
                        name: 'artifacts-ubuntu-focal'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'artifacts/*.deb',
                            fingerprint: true
                        }
                    }
                }
            }
        }
        stage('Upload To Playground') {
            when {
                anyOf {
                    expression { params.PLAYGROUND == true }
                }
            }
            steps {
                // unstash 'artifacts-ubuntu-bionic'
                unstash 'artifacts-ubuntu-focal'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = '''{
                        "files": [
                            {
                                "pattern": "artifacts/*bionic*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=bionic;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            }
                        ]
                    }'''
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload & Promotion Config') {
            when {
                buildingTag()
            }
            steps {
                // unstash 'artifacts-ubuntu-bionic'
                unstash 'artifacts-ubuntu-focal'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    def config

                    //ubuntu
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += '-ubuntu'
                    uploadSpec = '''{
                        "files": [
                            {
                                "pattern": "artifacts/*bionic*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=bionic;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            }
                        ]
                    }'''
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'ubuntu-rc',
                            'targetRepo'         : 'ubuntu-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server,
                    promotionConfig: config,
                    displayName: 'Ubuntu Promotion to Release'
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }
}

