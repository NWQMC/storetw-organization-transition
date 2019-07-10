#!/bin/bash

${LIQUIBASE_HOME}/liquibase \
	--classpath=${LIQUIBASE_HOME}/lib/${JDBC_JAR} \
	--changeLogFile=${LIQUIBASE_WORKSPACE_EPA}/changeLog.yml \
	--driver=org.postgresql.Driver \
	--url=jdbc:postgresql://${EPA_DATABASE_ADDRESS}:5432/${EPA_DATABASE_NAME} \
	--username=${EPA_SCHEMA_OWNER_USERNAME} \
	--password=${EPA_SCHEMA_OWNER_PASSWORD} \
	--contexts=${CONTEXTS} \
	--logLevel=debug\
	--liquibaseCatalogName=${STORETW_SCHEMA_NAME} \
	--liquibaseSchemaName=${STORETW_SCHEMA_NAME} \
	update \
	-DSTORETW_SCHEMA_NAME=${STORETW_SCHEMA_NAME}
