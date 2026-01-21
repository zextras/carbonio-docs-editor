library(
    identifier: 'jenkins-lib-common@1.3.0',
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
                            'rocky-8': [
                                preBuildScript: '''
                                    echo "[Zextras]" > zextras.repo
                                    echo "name=Zextras" >> zextras.repo
                                    echo "baseurl=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/centos8-''' + env.REPO_ENV + '''/" >> zextras.repo
                                    echo "enabled=1" >> zextras.repo
                                    echo "gpgcheck=0" >> zextras.repo
                                    echo "gpgkey=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/centos8-''' + env.REPO_ENV + '''/repomd.xml.key" >> zextras.repo
                                    echo "[nodesource-nodejs]" > nodesource-nodistro.repo
                                    echo "name=NodeSource" >> nodesource-nodistro.repo
                                    echo "baseurl=https://rpm.nodesource.com/pub_$NODE_MAJOR.x/nodistro/nodejs/x86_64" >> nodesource-nodistro.repo
                                    echo "enabled=1" >> nodesource-nodistro.repo
                                    echo "gpgcheck=0" >> nodesource-nodistro.repo
                                    mv *.repo /etc/yum.repos.d/
                                    dnf install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
                                ''',
                                branchBuildDirs: [
                                    devel: [ 'rpm-only', '.' ]
                                ]
                            ],
                            'rocky-9': [
                                preBuildScript: '''
                                    echo "[Zextras]" > zextras.repo
                                    echo "name=Zextras" >> zextras.repo
                                    echo "baseurl=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/rhel9-''' + env.REPO_ENV + '''/" >> zextras.repo
                                    echo "enabled=1" >> zextras.repo
                                    echo "gpgcheck=0" >> zextras.repo
                                    echo "gpgkey=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/rhel9-''' + env.REPO_ENV + '''/repomd.xml.key" >> zextras.repo
                                    echo "[nodesource-nodejs]" > nodesource-nodistro.repo
                                    echo "name=NodeSource" >> nodesource-nodistro.repo
                                    echo "baseurl=https://rpm.nodesource.com/pub_$NODE_MAJOR.x/nodistro/nodejs/x86_64" >> nodesource-nodistro.repo
                                    echo "enabled=1" >> nodesource-nodistro.repo
                                    echo "gpgcheck=0" >> nodesource-nodistro.repo
                                    mv *.repo /etc/yum.repos.d/
                                    dnf install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
                                ''',
                                branchBuildDirs: [
                                    devel: [ 'rpm-only', '.' ]
                                ]
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
