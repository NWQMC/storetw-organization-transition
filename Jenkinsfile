pipeline {
  agent {
    node {
      label 'team:iow'
    }
  }
  stages {
    stage('Set Build Description') {
      steps {
        script {
          currentBuild.description = "Deploy to ${env.DEPLOY_STAGE}"
        }
      }
    }
    stage('Clean Workspace') {
      steps {
        cleanWs()
      }
    }
    stage('Git Clone') {
      steps {
        checkout([
            $class: 'GitSCM',
            branches: [[name: '*/postgresql']],
            doGenerateSubmoduleConfigurations: false,
            extensions: [],
            submoduleCfg: [],
            userRemoteConfigs: [[credentialsId: 'CIDA-Jenkins-GitHub',
            url: 'https://github.com/NWQMC/storetw-organization-transition.git']]])
      }
    }
    stage('Download liquibase jar') {
      steps {
        sh '''mkdir $WORKSPACE/epa
          /usr/local/bin/aws s3 cp s3://owi-common-resources/resources/InstallFiles/liquibase/liquibase-$LIQUIBASE_VERSION.tar.gz $WORKSPACE/epa/liquibase.tar.gz
          /usr/bin/tar xzf $WORKSPACE/epa/liquibase.tar.gz --overwrite -C $WORKSPACE/epa
          /usr/local/bin/aws s3 cp s3://owi-common-resources/resources/InstallFiles/postgres/$JDBC_JAR $WORKSPACE/epa/lib/$JDBC_JAR
        '''
      }
    }
    stage('Run liquibase') {
      steps {
        script {
          def mappedStage = ""
          def deployStage = "$DEPLOY_STAGE"
          switch(deployStage) {
            case "PROD-EXTERNAL":
              mappedStage = "legacy-production-external"
              break
            case "QA":
              mappedStage = "legacy-qa"
              break
            case "TEST":
              mappedStage = "legacy-test"
              break
            default:
              mappedStage = "development"
          }
          env.MAPPED_STAGE = mappedStage
          def dbAdminSecret = sh(script: '/usr/local/bin/aws secretsmanager get-secret-value --secret-id "/observations-db-$MAPPED_STAGE/$MAPPED_STAGE/rds-admin-password" --region "us-west-2"', returnStdout: true).trim()
          def secretsString = sh(script: '/usr/local/bin/aws ssm get-parameter --name "/aws/reference/secretsmanager/WQP-EXTERNAL-$DEPLOY_STAGE" --query "Parameter.Value" --with-decryption --output text --region "us-west-2"', returnStdout: true).trim()
          def dbAdminSecretJson = readJSON text: dbAdminSecret
          def secretsJson =  readJSON text: secretsString

          env.POSTGRES_PASSWORD = dbAdminSecretJson.SecretString

          env.WQP_SCHEMA_NAME = secretsJson.WQP_SCHEMA_NAME
          env.WQP_SCHEMA_OWNER_USERNAME = secretsJson.WQP_SCHEMA_OWNER_USERNAME
          env.WQP_SCHEMA_OWNER_PASSWORD = secretsJson.WQP_SCHEMA_OWNER_PASSWORD

          env.EPA_DATABASE_ADDRESS = secretsJson.DATABASE_ADDRESS
          env.EPA_DATABASE_NAME = secretsJson.DATABASE_NAME
          env.EPA_SCHEMA_OWNER_USERNAME = secretsJson.EPA_SCHEMA_OWNER_USERNAME
          env.EPA_SCHEMA_OWNER_PASSWORD = secretsJson.EPA_SCHEMA_OWNER_PASSWORD
          env.STORETW_SCHEMA_NAME = secretsJson.STORETW_SCHEMA_NAME

          sh '''
            export CONTEXTS=$CONTEXTS
            export LIQUIBASE_HOME=$WORKSPACE/epa
            export LIQUIBASE_WORKSPACE_EPA=$WORKSPACE/liquibase/changeLogs

            chmod +x $WORKSPACE/scripts/z1_epa_liquibase.sh
            $WORKSPACE/scripts/z1_epa_liquibase.sh
            '''
        }
      }
    }
  }
}
