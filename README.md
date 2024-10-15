implement streaming database change data capture to kafka

# step by step  
setup `kafka-broker`, `debezium-connector`, `zookeeper`
  ```
    make cdc-infrastructure
  ```

1. setting up postgres [link](https://debezium.io/documentation/reference/3.0/connectors/postgresql.html#setting-up-postgresql)
  - choose the plutgin to decode data `decoderbufs` or `pgoutput` usually use `pgoutput`
  - setting write ahead log(wal_level) if choice `pgoutput`
    - edit file postgresql.conf
      ```sh
        vi /var/lib/postgresql/data/postgresql.conf
      ```
      change to:
      ```
        wal_level = logical             # minimal, replica, or logical
        max_wal_senders = 10            # max number of walsender processes                                            
        max_replication_slots = 10      # max number of replication slots 
      ```
   - create role if you use another account that not `postgres`
      - Create a replication group.
      ```sql
        CREATE ROLE <replication_group>;
      ```
      - Add the original owner of the table to the group.
      ```
        GRANT REPLICATION_GROUP TO <original_owner>;
      ```
      - Add the Debezium replication user to the group.
      ```
        GRANT REPLICATION_GROUP TO <replication_user>;
      ```
      - Transfer ownership of the table to <replication_group>.
      ```
        ALTER TABLE <table_name> OWNER TO REPLICATION_GROUP;
      ```

    - set permission and trust after create user
      - edit file pg_hba.conf vi /var/lib/postgresql/data/pg_hba.conf        
      - change to
       ```sh
        local    mydatabase      myuser                     trust
       ```              
  *note: restart database is requires
  
1. deploy [link](https://debezium.io/documentation/reference/3.0/connectors/postgresql.html#postgresql-deployment)
  - call api to connect from postgres to debezium
    ```sh
      curl --location 'http://localhost:8083/connectors/' \
      --header 'Accept: application/json' \
      --header 'Content-Type: application/json' \
      --data '{
          "name": "meilisearch-connector",
          "config": {
              "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
              "tasks.max": "1",
              "database.hostname": "your_host",
              "database.port": "5432",
              "database.user": "your_user",
              "database.password": "your_pass",
              "database.dbname" : "your_db",
              "topic.prefix": "meilisearch",
              "schema.include.list": "public",
              "slot.name": "meilisearch_slot_v1",
              "plugin.name": "pgoutput"              
          }
      }'
    ``` 
  - connect to `kafka-broker` to see the message output 
    ``` 
      kafka/bin/kafka-console-consumer.sh     --bootstrap-server kafka:9092     --from-beginning     --property print.key=true     --topic <topic_prefix>.<schema>.<table>
    ```