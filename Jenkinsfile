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
        NODE_MAJOR = '18'
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
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[credentialsId: 'jenkins-integration-with-github-account',
                                               name: 'carbonio-docs-branding',
                                               refspec: "refs/tags/23.05.12",
                                               url: 'git@github.com:Zextras/carbonio-docs-branding.git'
                                             ]]
                         ])
                }
                stash includes: '**', name: 'project'
            }
        }
        stage('Ubuntu 20') {
            agent {
                node {
                    label 'yap-agent-ubuntu-20.04-v2'
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
                sh 'echo "deb https://zextras.jfrog.io/artifactory/ubuntu-rc focal main" > zextras.list'
                sh 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52FD40243E584A21'
                sh 'echo "deb [trusted=yes] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > nodesource.list'
                sh 'sudo mv *.list /etc/apt/sources.list.d/'
                sh 'sudo mv theme /tmp'
                script {
                    if (BRANCH_NAME == 'devel') {
                        def timestamp = new Date().format('yyyyMMddHHmmss')
                        sh "sudo yap build ubuntu-focal . -r ${timestamp}"
                    } else {
                        sh 'sudo yap build ubuntu-focal .'
                    }
                }
                stash includes: 'artifacts/*focal*.deb',
                name: 'artifacts-ubuntu-focal'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'artifacts/*focal*.deb',
                    fingerprint: true
                }
            }
        }
        stage('Ubuntu 22') {
            agent {
                node {
                    label 'yap-agent-ubuntu-22.04-v2'
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
                sh 'echo "deb https://zextras.jfrog.io/artifactory/ubuntu-rc jammy main" > zextras.list'
                sh 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52FD40243E584A21'
                sh 'echo "deb [trusted=yes] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > nodesource.list'
                sh 'sudo mv *.list /etc/apt/sources.list.d/'
                sh 'sudo mv theme /tmp'
                script {
                    if (BRANCH_NAME == 'devel') {
                        def timestamp = new Date().format('yyyyMMddHHmmss')
                        sh "sudo yap build ubuntu-jammy . -r ${timestamp}"
                    } else {
                        sh 'sudo yap build ubuntu-jammy .'
                    }
                }
                stash includes: 'artifacts/*jammy*.deb',
                name: 'artifacts-ubuntu-jammy'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'artifacts/*jammy*.deb',
                    fingerprint: true
                }
            }
        }
        stage('Ubuntu 24') {
            agent {
                node {
                    label 'yap-agent-ubuntu-24.04-v2'
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
                sh 'echo "deb https://zextras.jfrog.io/artifactory/ubuntu-devel noble main" > zextras.list'
                sh 'sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52FD40243E584A21'
                sh 'echo "deb [trusted=yes] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > nodesource.list'
                sh 'sudo mv *.list /etc/apt/sources.list.d/'
                sh 'sudo mv theme /tmp'
                script {
                    if (BRANCH_NAME == 'devel') {
                        def timestamp = new Date().format('yyyyMMddHHmmss')
                        sh "sudo yap build ubuntu-noble . -r ${timestamp}"
                    } else {
                        sh 'sudo yap build ubuntu-noble .'
                    }
                }
                stash includes: 'artifacts/*noble*.deb',
                name: 'artifacts-ubuntu-noble'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'artifacts/*noble*.deb',
                    fingerprint: true
                }
            }
        }
        stage('Rocky 8') {
            agent {
                node {
                    label 'yap-agent-rocky-8-v2'
                }
            }
            steps {
                unstash 'project'
                withCredentials([usernamePassword(credentialsId: 'artifactory-jenkins-gradle-properties-splitted', 
                    passwordVariable: 'SECRET',
                    usernameVariable: 'USERNAME')]) {
                        sh 'echo "[Zextras]" > zextras.repo'
                        sh 'echo "baseurl=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/centos8-rc/" >> zextras.repo'
                        sh 'echo "enabled=1" >> zextras.repo'
                        sh 'echo "gpgcheck=0" >> zextras.repo'
                        sh 'echo "gpgkey=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/centos8-rc/repomd.xml.key" >> zextras.repo'

                        sh 'echo "[nodesource-nodejs]" > nodesource-nodistro.repo'
                        sh 'echo "baseurl=https://rpm.nodesource.com/pub_$NODE_MAJOR.x/nodistro/nodejs/x86_64" >> nodesource-nodistro.repo'
                        sh 'echo "enabled=1" >> nodesource-nodistro.repo'
                        sh 'echo "gpgcheck=0" >> nodesource-nodistro.repo'
                        sh 'sudo mv *.repo /etc/yum.repos.d/'
                        sh 'sudo dnf install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1'
                }
                sh 'sudo mv theme /tmp'
                script {
                    if (BRANCH_NAME == 'devel') {
                        def timestamp = new Date().format('yyyyMMddHHmmss')
                        sh "sudo yap build rocky-8 rpm-only -r ${timestamp}"
                        sh "sudo yap build rocky-8 . -r ${timestamp}"
                    } else {
                        sh 'sudo yap build rocky-8 .'
                    }
                }
                stash includes: 'artifacts/x86_64/*el8*.rpm',
                name: 'artifacts-rocky-8'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'artifacts/x86_64/*el8*.rpm',
                    fingerprint: true
                }
            }
        }
        stage('Rocky 9') {
            agent {
                node {
                    label 'yap-agent-rocky-9-v2'
                }
            }
            steps {
                unstash 'project'
                withCredentials([usernamePassword(credentialsId: 'artifactory-jenkins-gradle-properties-splitted',
                    passwordVariable: 'SECRET',
                    usernameVariable: 'USERNAME')]) {
                        sh 'echo "[Zextras]" > zextras.repo'
                        sh 'echo "baseurl=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/rhel9-rc/" >> zextras.repo'
                        sh 'echo "enabled=1" >> zextras.repo'
                        sh 'echo "gpgcheck=0" >> zextras.repo'
                        sh 'echo "gpgkey=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/rhel9-rc/repomd.xml.key" >> zextras.repo'
                        sh 'echo "[nodesource-nodejs]" > nodesource-nodistro.repo'

                        sh 'echo "baseurl=https://rpm.nodesource.com/pub_$NODE_MAJOR.x/nodistro/nodejs/x86_64" >> nodesource-nodistro.repo'
                        sh 'echo "enabled=1" >> nodesource-nodistro.repo'
                        sh 'echo "gpgcheck=0" >> nodesource-nodistro.repo'
                        sh 'sudo mv *.repo /etc/yum.repos.d/'
                        sh 'sudo dnf install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1'
                }
                sh 'sudo mv theme /tmp'
                script {
                    if (BRANCH_NAME == 'devel') {
                        def timestamp = new Date().format('yyyyMMddHHmmss')
                        sh "sudo yap build rocky-9 rpm-only -r ${timestamp}"
                        sh "sudo yap build rocky-9 . -r ${timestamp}"
                    } else {
                        sh 'sudo yap build rocky-9 .'
                    }
                }
                stash includes: 'artifacts/x86_64/*el9*.rpm',
                name: 'artifacts-rocky-9'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'artifacts/x86_64/*el9*.rpm',
                    fingerprint: true
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
                unstash 'artifacts-ubuntu-focal'
                unstash 'artifacts-ubuntu-jammy'
                unstash 'artifacts-ubuntu-noble'
                unstash 'artifacts-rocky-8'
                unstash 'artifacts-rocky-9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = '''{
                        "files": [
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*jammy*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*noble*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-docs-editor)-(*).el8.x86_64.rpm",
                                "target": "centos8-playground/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-docs-editor)-(*).el9.x86_64.rpm",
                                "target": "rhel9-playground/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }'''
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload To Devel') {
            when {
                branch 'devel'
            }
            steps {
                unstash 'artifacts-ubuntu-focal'
                unstash 'artifacts-ubuntu-jammy'
                unstash 'artifacts-ubuntu-noble'
                unstash 'artifacts-rocky-8'
                unstash 'artifacts-rocky-9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = '''{
                        "files": [
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*jammy*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*noble*.deb",
                                "target": "ubuntu-devel/pool/",
                                "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-docs-editor)-(*).el8.x86_64.rpm",
                                "target": "centos8-devel/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            },
                            {
                                "pattern": "artifacts/x86_64/(carbonio-docs-editor)-(*).el9.x86_64.rpm",
                                "target": "rhel9-devel/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
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
                unstash 'artifacts-ubuntu-focal'
                unstash 'artifacts-ubuntu-jammy'
                unstash 'artifacts-ubuntu-noble'
                unstash 'artifacts-rocky-8'
                unstash 'artifacts-rocky-9'

                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    def config

                    // ubuntu
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-ubuntu"
                    uploadSpec = """{
                        "files": [
                            {
                                "pattern": "artifacts/*focal*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*jammy*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=jammy;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/*noble*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=noble;deb.component=main;deb.architecture=amd64"
                            }
                        ]
                    }"""
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
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Ubuntu Promotion to Release"
                    server.publishBuildInfo buildInfo

                    // rhel8
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-centos8"
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/x86_64/(carbonio-docs-editor)-(*).el8.x86_64.rpm",
                                "target": "centos8-rc/zextras/{1}/{1}-{2}.el8.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'centos8-rc',
                            'targetRepo'         : 'centos8-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Centos8 Promotion to Release"
                    server.publishBuildInfo buildInfo

                    // rhel9
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-rhel9"
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/x86_64/(carbonio-docs-editor)-(*).el9.x86_64.rpm",
                                "target": "rhel9-rc/zextras/{1}/{1}-{2}.el9.x86_64.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'rhel9-rc',
                            'targetRepo'         : 'rhel9-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "RHEL9 Promotion to Release"
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }
}

