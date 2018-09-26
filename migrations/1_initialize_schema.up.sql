CREATE TYPE PROJECT_ROLE_ENUM AS ENUM ('OPERATOR', 'CUSTOMER', 'MEMBER', 'PROJECT_MANAGER');

CREATE TYPE STATUS_ENUM AS ENUM ('IN_PROGRESS', 'PASSED', 'FAILED', 'STOPPED', 'SKIPPED', 'INTERRUPTED', 'RESETED', 'CANCELLED');

CREATE TYPE LAUNCH_MODE_ENUM AS ENUM ('DEFAULT', 'DEBUG');

CREATE TYPE AUTH_TYPE_ENUM AS ENUM ('OAUTH', 'NTLM', 'APIKEY', 'BASIC');

CREATE TYPE ACCESS_TOKEN_TYPE_ENUM AS ENUM ('OAUTH', 'NTLM', 'APIKEY', 'BASIC');

CREATE TYPE ACTIVITY_ENTITY_ENUM AS ENUM ('LAUNCH', 'ITEM');

CREATE TYPE TEST_ITEM_TYPE_ENUM AS ENUM ('SUITE', 'STORY', 'TEST', 'SCENARIO', 'STEP', 'BEFORE_CLASS', 'BEFORE_GROUPS', 'BEFORE_METHOD',
  'BEFORE_SUITE', 'BEFORE_TEST', 'AFTER_CLASS', 'AFTER_GROUPS', 'AFTER_METHOD', 'AFTER_SUITE', 'AFTER_TEST');

CREATE TYPE ISSUE_GROUP_ENUM AS ENUM ('PRODUCT_BUG', 'AUTOMATION_BUG', 'SYSTEM_ISSUE', 'TO_INVESTIGATE', 'NO_DEFECT');

CREATE TYPE INTEGRATION_AUTH_FLOW_ENUM AS ENUM ('OAUTH', 'BASIC', 'TOKEN', 'FORM', 'LDAP');

CREATE TYPE INTEGRATION_GROUP_ENUM AS ENUM ('BTS', 'NOTIFICATION');

CREATE TYPE FILTER_CONDITION_ENUM AS ENUM ('EQUALS', 'NOT_EQUALS', 'CONTAINS', 'EXISTS', 'IN', 'HAS', 'GREATER_THAN', 'GREATER_THAN_OR_EQUALS',
  'LOWER_THAN', 'LOWER_THAN_OR_EQUALS', 'BETWEEN');

CREATE TYPE PASSWORD_ENCODER_TYPE AS ENUM ('PLAIN', 'SHA', 'LDAP_SHA', 'MD4', 'MD5');

CREATE TYPE SORT_DIRECTION_ENUM AS ENUM ('ASC', 'DESC');

CREATE EXTENSION ltree;

CREATE TABLE server_settings (
  id    SMALLSERIAL CONSTRAINT server_settings_id PRIMARY KEY,
  key   VARCHAR NOT NULL UNIQUE,
  value VARCHAR
);

---------------------------- Project and users ------------------------------------
CREATE TABLE project (
  id              BIGSERIAL CONSTRAINT project_pk PRIMARY KEY,
  name            VARCHAR                 NOT NULL UNIQUE,
  additional_info VARCHAR,
  creation_date   TIMESTAMP DEFAULT now() NOT NULL,
  metadata        JSONB                   NULL
);

CREATE TABLE demo_data_postfix (
  id         BIGSERIAL CONSTRAINT demo_data_postfix_pk PRIMARY KEY,
  data       VARCHAR NOT NULL,
  project_id BIGINT REFERENCES project (id) ON DELETE CASCADE
);

CREATE TABLE users (
  id                   BIGSERIAL CONSTRAINT users_pk PRIMARY KEY,
  login                VARCHAR NOT NULL UNIQUE,
  password             VARCHAR NULL,
  email                VARCHAR NOT NULL,
  attachment           VARCHAR NULL,
  attachment_thumbnail VARCHAR NULL,
  role                 VARCHAR NOT NULL,
  type                 VARCHAR NOT NULL,
  expired              BOOLEAN NOT NULL,
  default_project_id   BIGINT REFERENCES project (id) ON DELETE CASCADE,
  full_name            VARCHAR NOT NULL,
  metadata             JSONB   NULL
);

CREATE TABLE user_config (
  id           BIGSERIAL CONSTRAINT user_config_pk PRIMARY KEY,
  user_id      BIGINT REFERENCES users (id) ON DELETE CASCADE,
  project_id   BIGINT REFERENCES project (id) ON DELETE CASCADE,
  proposedRole VARCHAR,
  projectRole  VARCHAR
);

CREATE TABLE project_user (
  user_id      BIGINT REFERENCES users (id) ON DELETE CASCADE,
  project_id   BIGINT REFERENCES project (id) ON DELETE CASCADE,
  CONSTRAINT users_project_pk PRIMARY KEY (user_id, project_id),
  project_role PROJECT_ROLE_ENUM NOT NULL
);

CREATE TABLE oauth_access_token (
  user_id    BIGINT REFERENCES users (id) ON DELETE CASCADE,
  token      VARCHAR                NOT NULL,
  token_type ACCESS_TOKEN_TYPE_ENUM NOT NULL,
  CONSTRAINT access_tokens_pk PRIMARY KEY (user_id, token_type)
);

CREATE TABLE oauth_registration (
  id                           VARCHAR(64) PRIMARY KEY,
  client_id                    VARCHAR(128) NOT NULL UNIQUE,
  client_secret                VARCHAR(256),
  client_auth_method           VARCHAR(64)  NOT NULL,
  auth_grant_type              VARCHAR(64),
  redirect_uri_template        VARCHAR(256),

  authorization_uri            VARCHAR(256),
  token_uri                    VARCHAR(256),

  user_info_endpoint_uri       VARCHAR(256),
  user_info_endpoint_name_attr VARCHAR(256),

  jwk_set_uri                  VARCHAR(256),
  client_name                  VARCHAR(128)
);

CREATE TABLE oauth_registration_scope (
  id                    SERIAL CONSTRAINT oauth_registration_scope_pk PRIMARY KEY,
  oauth_registration_fk VARCHAR(128) REFERENCES oauth_registration (id) ON DELETE CASCADE,
  scope                 VARCHAR(256),
  CONSTRAINT oauth_registration_scope_unique UNIQUE (scope, oauth_registration_fk)
);

CREATE TABLE oauth_registration_restriction (
  id                    SERIAL CONSTRAINT oauth_registration_restriction_pk PRIMARY KEY,
  oauth_registration_fk VARCHAR(128) REFERENCES oauth_registration (id) ON DELETE CASCADE,
  type                  VARCHAR(256) NOT NULL,
  value                 VARCHAR(256) NOT NULL,
  CONSTRAINT oauth_registration_restriction_unique UNIQUE (type, value, oauth_registration_fk)
);
-----------------------------------------------------------------------------------


------------------------------ Project configurations ------------------------------
CREATE TABLE email_sender_case (
  id         BIGSERIAL CONSTRAINT email_sender_case_pk PRIMARY KEY,
  send_case  VARCHAR(64),
  project_id BIGSERIAL REFERENCES project (id) ON DELETE CASCADE
);

CREATE TABLE recipients (
  email_sender_case_id BIGINT REFERENCES email_sender_case (id) ON DELETE CASCADE,
  recipient            VARCHAR(256)
);

CREATE TABLE attribute (
  id   BIGSERIAL CONSTRAINT attribute_pk PRIMARY KEY,
  name VARCHAR(256)
);

CREATE TABLE project_attribute (
  attribute_id BIGSERIAL REFERENCES attribute (id),
  value        VARCHAR(256) NOT NULL,
  project_id   BIGSERIAL REFERENCES project (id),
  PRIMARY KEY (attribute_id, project_id),
  CONSTRAINT unique_attribute_per_project UNIQUE (attribute_id, project_id)
);
-----------------------------------------------------------------------------------


------------------------------ Bug tracking systems ------------------------------
CREATE TABLE bug_tracking_system (
  id          BIGSERIAL CONSTRAINT bug_tracking_system_pk PRIMARY KEY,
  url         VARCHAR                                          NOT NULL,
  type        VARCHAR                                          NOT NULL,
  bts_project VARCHAR                                          NOT NULL,
  project_id  BIGINT REFERENCES project (id) ON DELETE CASCADE NOT NULL,
  CONSTRAINT unique_bts UNIQUE (url, type, bts_project, project_id)
);

CREATE TABLE defect_form_field (
  id                     BIGSERIAL CONSTRAINT defect_form_field_pk PRIMARY KEY,
  bug_tracking_system_id BIGINT REFERENCES bug_tracking_system (id) ON DELETE CASCADE,
  field_id               VARCHAR NOT NULL,
  type                   VARCHAR NOT NULL,
  required               BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE defect_field_allowed_value (
  id                BIGSERIAL CONSTRAINT defect_field_allowed_value_pk PRIMARY KEY,
  defect_form_field BIGINT REFERENCES defect_form_field (id) ON DELETE CASCADE,
  value_id          VARCHAR NOT NULL,
  value_name        VARCHAR NOT NULL
);

CREATE TABLE defect_form_field_value (
  id     BIGINT REFERENCES defect_form_field (id) ON DELETE CASCADE,
  values VARCHAR NOT NULL
);

-----------------------------------------------------------------------------------


-------------------------- Integrations -----------------------------
CREATE TABLE integration_type (
  id            SERIAL CONSTRAINT integration_type_pk PRIMARY KEY,
  name          VARCHAR(128)               NOT NULL,
  auth_flow     INTEGRATION_AUTH_FLOW_ENUM NOT NULL,
  creation_date TIMESTAMP DEFAULT now()    NOT NULL,
  group_type    INTEGRATION_GROUP_ENUM     NOT NULL,
  details       JSONB                      NULL
);

CREATE TABLE integration (
  id            SERIAL CONSTRAINT integration_pk PRIMARY KEY,
  project_id    BIGINT REFERENCES project (id) ON DELETE CASCADE,
  type          INTEGER REFERENCES integration_type (id) ON DELETE CASCADE,
  enabled       BOOLEAN,
  params        JSONB                   NULL,
  creation_date TIMESTAMP DEFAULT now() NOT NULL
);

-------------------------------- LDAP configurations ------------------------------
CREATE TABLE ldap_synchronization_attributes
(
  id        BIGSERIAL CONSTRAINT ldap_synchronization_attributes_pk PRIMARY KEY,
  email     VARCHAR(256) UNIQUE,
  full_name VARCHAR(256),
  photo     VARCHAR(128)
);

CREATE TABLE active_directory_config
(
  id                 BIGINT CONSTRAINT active_directory_config_pk PRIMARY KEY REFERENCES integration (id) ON DELETE CASCADE UNIQUE,
  url                VARCHAR(256),
  base_dn            VARCHAR(256),
  sync_attributes_id BIGINT REFERENCES ldap_synchronization_attributes (id) ON DELETE CASCADE,
  domain             VARCHAR(256)
);

CREATE TABLE ldap_config
(
  id                  BIGINT CONSTRAINT ldap_config_pk PRIMARY KEY REFERENCES integration (id) ON DELETE CASCADE UNIQUE,
  url                 VARCHAR(256),
  base_dn             VARCHAR(256),
  sync_attributes_id  BIGINT REFERENCES ldap_synchronization_attributes (id) ON DELETE CASCADE,
  user_dn_pattern     VARCHAR(256),
  user_search_filter  VARCHAR(256),
  group_search_base   VARCHAR(256),
  group_search_filter VARCHAR(256),
  password_attributes VARCHAR(256),
  manager_dn          VARCHAR(256),
  manager_password    VARCHAR(256),
  passwordEncoderType PASSWORD_ENCODER_TYPE
);

CREATE TABLE auth_config (
  id                         VARCHAR CONSTRAINT auth_config_pk PRIMARY KEY,
  ldap_config_id             BIGINT REFERENCES ldap_config (id) ON DELETE CASCADE,
  active_directory_config_id BIGINT REFERENCES active_directory_config (id) ON DELETE CASCADE
);

-----------------------------------------------------------------------------------

-------------------------- Dashboards, widgets, user filters -----------------------------

CREATE TABLE filter (
  id          BIGSERIAL CONSTRAINT filter_pk PRIMARY KEY,
  name        VARCHAR                        NOT NULL,
  project_id  BIGINT REFERENCES project (id) NOT NULL,
  target      VARCHAR                        NOT NULL,
  description VARCHAR
);

CREATE TABLE user_filter (
  id BIGINT NOT NULL CONSTRAINT user_filter_pk PRIMARY KEY CONSTRAINT user_filter_id_fk REFERENCES filter (id)
);

CREATE TABLE filter_condition (
  id        BIGSERIAL CONSTRAINT filter_condition_pk PRIMARY KEY,
  filter_id BIGINT REFERENCES user_filter (id) ON DELETE CASCADE,
  condition FILTER_CONDITION_ENUM NOT NULL,
  value     VARCHAR               NOT NULL,
  field     VARCHAR               NOT NULL,
  negative  BOOLEAN               NOT NULL
);

CREATE TABLE filter_sort (
  id        BIGSERIAL CONSTRAINT filter_sort_pk PRIMARY KEY,
  filter_id BIGINT REFERENCES user_filter (id) ON DELETE CASCADE,
  field     VARCHAR             NOT NULL,
  direction SORT_DIRECTION_ENUM NOT NULL DEFAULT 'ASC'
);

CREATE TABLE dashboard (
  id            SERIAL CONSTRAINT dashboard_pk PRIMARY KEY,
  name          VARCHAR                 NOT NULL,
  description   VARCHAR,
  project_id    INTEGER REFERENCES project (id) ON DELETE CASCADE,
  creation_date TIMESTAMP DEFAULT now() NOT NULL,
  CONSTRAINT unq_name_project UNIQUE (name, project_id)
  -- acl
);

CREATE TABLE widget (
  id          BIGSERIAL CONSTRAINT widget_id PRIMARY KEY,
  name        VARCHAR NOT NULL,
  description VARCHAR,
  widget_type VARCHAR NOT NULL,
  items_count SMALLINT,
  project_id  BIGINT REFERENCES project (id) ON DELETE CASCADE
);

CREATE TABLE content_field (
  id    BIGINT REFERENCES widget (id) ON DELETE CASCADE,
  field VARCHAR NOT NULL
);

CREATE TABLE widget_option (
  id        BIGSERIAL CONSTRAINT widget_option_pk PRIMARY KEY,
  widget_id BIGINT REFERENCES widget (id) ON DELETE CASCADE,
  option    VARCHAR NOT NULL,
  value     VARCHAR NOT NULL
);

CREATE TABLE dashboard_widget (
  dashboard_id      INTEGER REFERENCES dashboard (id) ON DELETE CASCADE,
  widget_id         INTEGER REFERENCES widget (id) ON DELETE CASCADE,
  widget_name       VARCHAR NOT NULL, -- make it as reference ??
  widget_width      INT     NOT NULL,
  widget_height     INT     NOT NULL,
  widget_position_x INT     NOT NULL,
  widget_position_y INT     NOT NULL,
  CONSTRAINT dashboard_widget_pk PRIMARY KEY (dashboard_id, widget_id),
  CONSTRAINT widget_on_dashboard_unq UNIQUE (dashboard_id, widget_name)
);

CREATE TABLE widget_filter (
  widget_id BIGINT REFERENCES widget (id) ON DELETE CASCADE         NOT NULL,
  filter_id BIGINT REFERENCES user_filter (id) ON DELETE CASCADE    NOT NULL,
  CONSTRAINT widget_filter_pk PRIMARY KEY (widget_id, filter_id)
);
-----------------------------------------------------------------------------------


--------------------------- Launches, items, logs --------------------------------------

CREATE TABLE launch (
  id                   BIGSERIAL CONSTRAINT launch_pk PRIMARY KEY,
  uuid                 VARCHAR                                                             NOT NULL,
  project_id           BIGINT REFERENCES project (id) ON DELETE CASCADE                    NOT NULL,
  user_id              BIGINT REFERENCES users (id) ON DELETE SET NULL,
  name                 VARCHAR(256)                                                        NOT NULL,
  description          TEXT,
  start_time           TIMESTAMP                                                           NOT NULL,
  end_time             TIMESTAMP,
  number               INTEGER                                                             NOT NULL,
  last_modified        TIMESTAMP DEFAULT now()                                             NOT NULL,
  mode                 LAUNCH_MODE_ENUM                                                    NOT NULL,
  status               STATUS_ENUM                                                         NOT NULL,
  email_sender_case_id BIGINT REFERENCES email_sender_case (id) ON DELETE CASCADE,
  CONSTRAINT unq_name_number UNIQUE (NAME, number, project_id, uuid)
);

CREATE TABLE launch_tag (
  id                   BIGSERIAL CONSTRAINT launch_tag_pk PRIMARY KEY,
  value                TEXT NOT NULL,
  email_sender_case_id BIGINT REFERENCES email_sender_case (id) ON DELETE CASCADE,
  launch_id            BIGINT REFERENCES launch (id) ON DELETE CASCADE
);

CREATE TABLE test_item (
  item_id       BIGSERIAL CONSTRAINT test_item_pk PRIMARY KEY,
  name          VARCHAR(256),
  type          TEST_ITEM_TYPE_ENUM NOT NULL,
  start_time    TIMESTAMP           NOT NULL,
  description   TEXT,
  last_modified TIMESTAMP           NOT NULL,
  path          LTREE,
  unique_id     VARCHAR(256),
  parent_id     BIGINT REFERENCES test_item (item_id) ON DELETE CASCADE,
  retry_of      BIGINT REFERENCES test_item (item_id) ON DELETE CASCADE,
  launch_id     BIGINT REFERENCES launch (id) ON DELETE CASCADE
);

CREATE TABLE test_item_results (
  result_id BIGINT CONSTRAINT test_item_results_pk PRIMARY KEY REFERENCES test_item (item_id) ON DELETE CASCADE UNIQUE,
  status    STATUS_ENUM NOT NULL,
  end_time  TIMESTAMP,
  duration  DOUBLE PRECISION
);

CREATE INDEX path_gist_idx
  ON test_item
  USING GIST (path);
CREATE INDEX path_idx
  ON test_item
  USING BTREE (path);

CREATE TABLE parameter (
  item_id BIGINT REFERENCES test_item (item_id) ON DELETE CASCADE,
  key     VARCHAR NOT NULL,
  value   VARCHAR NOT NULL
);

CREATE TABLE item_tag (
  id      SERIAL CONSTRAINT item_tag_pk PRIMARY KEY,
  value   TEXT,
  item_id BIGINT REFERENCES test_item (item_id) ON DELETE CASCADE
);


CREATE TABLE log (
  id                   BIGSERIAL CONSTRAINT log_pk PRIMARY KEY,
  log_time             TIMESTAMP                                                NOT NULL,
  log_message          TEXT                                                     NOT NULL,
  item_id              BIGINT REFERENCES test_item (item_id) ON DELETE CASCADE  NOT NULL,
  last_modified        TIMESTAMP                                                NOT NULL,
  log_level            INTEGER                                                  NOT NULL,
  attachment           TEXT,
  attachment_thumbnail TEXT,
  content_type         TEXT
);

CREATE TABLE activity (
  id            BIGSERIAL CONSTRAINT activity_pk PRIMARY KEY,
  user_id       BIGINT REFERENCES users (id) ON DELETE CASCADE           NOT NULL,
  project_id    BIGINT REFERENCES project (id) ON DELETE CASCADE         NOT NULL,
  entity        ACTIVITY_ENTITY_ENUM                                     NOT NULL,
  action        VARCHAR(128)                                             NOT NULL,
  details       JSONB                                                    NULL,
  creation_date TIMESTAMP                                                NOT NULL
);

----------------------------------------------------------------------------------------


------------------------------ Issue ticket many to many ------------------------------

CREATE TABLE issue_group (
  issue_group_id SMALLSERIAL CONSTRAINT issue_group_pk PRIMARY KEY,
  issue_group    ISSUE_GROUP_ENUM NOT NULL
);

CREATE TABLE issue_type (
  id             BIGSERIAL CONSTRAINT issue_type_pk PRIMARY KEY,
  issue_group_id SMALLINT REFERENCES issue_group (issue_group_id) ON DELETE CASCADE,
  locator        VARCHAR(64) UNIQUE NOT NULL, -- issue string identifier
  issue_name     VARCHAR(256)       NOT NULL, -- issue full name
  abbreviation   VARCHAR(64)        NOT NULL, -- issue abbreviation
  hex_color      VARCHAR(7)         NOT NULL
);

CREATE TABLE statistics (
  s_id      BIGSERIAL NOT NULL CONSTRAINT pk_statistics PRIMARY KEY,
  s_field   VARCHAR   NOT NULL,
  s_counter INT DEFAULT 0,
  item_id   BIGINT REFERENCES test_item (item_id) ON DELETE CASCADE,
  launch_id BIGINT REFERENCES launch (id) ON DELETE CASCADE,

  CONSTRAINT unique_status_item UNIQUE (s_field, item_id),
  CONSTRAINT unique_status_launch UNIQUE (s_field, launch_id),
  CHECK (statistics.s_counter >= 0)
);

CREATE TABLE issue_type_project (
  project_id    BIGINT REFERENCES project,
  issue_type_id BIGINT REFERENCES issue_type,
  CONSTRAINT issue_type_project_pk PRIMARY KEY (project_id, issue_type_id)
);
----------------------------------------------------------------------------------------


CREATE TABLE issue (
  issue_id          BIGINT CONSTRAINT issue_pk PRIMARY KEY REFERENCES test_item_results (result_id) ON DELETE CASCADE,
  issue_type        BIGINT REFERENCES issue_type (id),
  issue_description TEXT,
  auto_analyzed     BOOLEAN DEFAULT FALSE,
  ignore_analyzer   BOOLEAN DEFAULT FALSE
);

CREATE TABLE ticket (
  id           BIGSERIAL CONSTRAINT ticket_pk PRIMARY KEY,
  ticket_id    VARCHAR(64)                                                   NOT NULL UNIQUE,
  submitter_id BIGINT REFERENCES users (id)                                  NOT NULL,
  submit_date  TIMESTAMP DEFAULT now()                                       NOT NULL,
  bts_id       INTEGER REFERENCES bug_tracking_system (id) ON DELETE CASCADE NOT NULL,
  url          VARCHAR(256)                                                  NOT NULL
);

CREATE TABLE issue_ticket (
  issue_id  BIGINT REFERENCES issue (issue_id),
  ticket_id BIGINT REFERENCES ticket (id),
  CONSTRAINT issue_ticket_pk PRIMARY KEY (issue_id, ticket_id)
);

CREATE EXTENSION IF NOT EXISTS tablefunc;

------- Functions and triggers -----------------------


CREATE OR REPLACE FUNCTION get_last_launch_number()
  RETURNS TRIGGER AS
$BODY$
BEGIN
  NEW.number = (SELECT number
                FROM launch
                WHERE name = NEW.name AND project_id = NEW.project_id
                ORDER BY number DESC
                LIMIT 1) + 1;
  NEW.number = CASE WHEN NEW.number IS NULL
    THEN 1
               ELSE NEW.number END;
  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE FUNCTION check_wired_tickets()
  RETURNS TRIGGER AS
$BODY$
BEGIN
  DELETE FROM ticket
  WHERE (SELECT count(issue_ticket.ticket_id)
         FROM issue_ticket
         WHERE issue_ticket.ticket_id = old.ticket_id) = 0 AND ticket.id = old.ticket_id;
  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql;


CREATE FUNCTION check_wired_widgets()
  RETURNS TRIGGER AS
$BODY$
BEGIN
  DELETE FROM widget
  WHERE (SELECT count(dashboard_widget.widget_id)
         FROM dashboard_widget
         WHERE dashboard_widget.widget_id = old.widget_id) = 0 AND widget.id = old.widget_id;
  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER after_ticket_delete
  AFTER DELETE
  ON issue_ticket
  FOR EACH ROW EXECUTE PROCEDURE check_wired_tickets();


CREATE TRIGGER after_widget_delete
  AFTER DELETE
  ON dashboard_widget
  FOR EACH ROW EXECUTE PROCEDURE check_wired_widgets();


CREATE TRIGGER last_launch_number_trigger
  BEFORE INSERT
  ON launch
  FOR EACH ROW
EXECUTE PROCEDURE get_last_launch_number();

-------------------------- Execution statistics triggers end functions ------------------------------

CREATE OR REPLACE FUNCTION update_executions_statistics()
  RETURNS TRIGGER AS $$
DECLARE   cur_id                 BIGINT;
  DECLARE executions_field       VARCHAR;
  DECLARE executions_field_old   VARCHAR;
  DECLARE executions_field_total VARCHAR;
  DECLARE cur_launch_id          BIGINT;

BEGIN
  IF exists(SELECT 1
            FROM test_item AS s
              JOIN test_item AS s2 ON s.item_id = s2.parent_id
            WHERE s.item_id = new.result_id)
  THEN RETURN new;
  END IF;

  cur_launch_id := (SELECT launch_id
                    FROM test_item
                    WHERE
                      test_item.item_id = new.result_id);

  executions_field := concat('statistics$executions$', lower(new.status :: VARCHAR));
  executions_field_total := 'statistics$executions$total';

  IF old.status = 'IN_PROGRESS' :: STATUS_ENUM
  THEN
    FOR cur_id IN
    (SELECT item_id
     FROM test_item
     WHERE PATH @> (SELECT PATH
                    FROM test_item
                    WHERE item_id = NEW.result_id))
    LOOP
      /* increment item executions statistics for concrete field */
      INSERT INTO statistics (s_counter, s_field, item_id) VALUES (1, executions_field, cur_id)
      ON CONFLICT (s_field, item_id)
        DO UPDATE SET s_counter = statistics.s_counter + 1;
      /* increment item executions statistics for total field */
      INSERT INTO statistics (s_counter, s_field, item_id) VALUES (1, executions_field_total, cur_id)
      ON CONFLICT (s_field, item_id)
        DO UPDATE SET s_counter = statistics.s_counter + 1;
    END LOOP;

    /* increment launch executions statistics for concrete field */
    INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, executions_field, cur_launch_id)
    ON CONFLICT (s_field, launch_id)
      DO UPDATE SET s_counter = statistics.s_counter + 1;
    /* increment launch executions statistics for total field */
    INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, executions_field_total, cur_launch_id)
    ON CONFLICT (s_field, launch_id)
      DO UPDATE SET s_counter = statistics.s_counter + 1;
    RETURN new;
  END IF;

  IF old.status != 'IN_PROGRESS' :: STATUS_ENUM AND old.status != new.status
  THEN
    executions_field_old := concat('statistics$executions$', lower(old.status :: VARCHAR));
    FOR cur_id IN
    (SELECT item_id
     FROM test_item
     WHERE PATH @> (SELECT PATH
                    FROM test_item
                    WHERE item_id = NEW.result_id))

    LOOP
      /* decrease item executions statistics for old field */
      UPDATE statistics
      SET s_counter = s_counter - 1
      WHERE s_field = executions_field_old AND item_id = cur_id;

      /* increment item executions statistics for concrete field */
      INSERT INTO STATISTICS (s_counter, s_field, item_id) VALUES (1, executions_field, cur_id)
      ON CONFLICT (s_field, item_id)
        DO UPDATE SET s_counter = STATISTICS.s_counter + 1;
    END LOOP;

    /* decrease item executions statistics for old field */
    UPDATE statistics
    SET s_counter = s_counter - 1
    WHERE s_field = executions_field_old AND launch_id = cur_launch_id;
    /* increment launch executions statistics for concrete field */
    INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, executions_field, cur_launch_id)
    ON CONFLICT (s_field, launch_id)
      DO UPDATE SET s_counter = statistics.s_counter + 1;
    RETURN new;
  END IF;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER after_test_results_update
  AFTER UPDATE
  ON test_item_results
  FOR EACH ROW EXECUTE PROCEDURE update_executions_statistics();


CREATE OR REPLACE FUNCTION increment_defect_statistics()
  RETURNS TRIGGER AS $$
DECLARE   cur_id             BIGINT;
  DECLARE defect_field       VARCHAR;
  DECLARE defect_field_total VARCHAR;
  DECLARE cur_launch_id      BIGINT;

BEGIN
  IF exists(SELECT 1
            FROM test_item AS s
              JOIN test_item AS s2 ON s.item_id = s2.parent_id
            WHERE s.item_id = new.issue_id)
  THEN RETURN new;
  END IF;

  cur_launch_id := (SELECT launch_id
                    FROM test_item
                    WHERE
                      test_item.item_id = new.issue_id);

  defect_field := (SELECT
                     concat('statistics$defects$', lower(public.issue_group.issue_group :: VARCHAR), '$', lower(public.issue_type.locator))
                   FROM issue
                     JOIN issue_type ON issue.issue_type = issue_type.id
                     JOIN issue_group ON issue_type.issue_group_id = issue_group.issue_group_id
                   WHERE issue.issue_id = new.issue_id);

  defect_field_total := (SELECT concat('statistics$defects$', lower(public.issue_group.issue_group :: VARCHAR), '$total')
                         FROM issue
                           JOIN issue_type ON issue.issue_type = issue_type.id
                           JOIN issue_group ON issue_type.issue_group_id = issue_group.issue_group_id
                         WHERE issue.issue_id = new.issue_id);
  FOR cur_id IN
  (SELECT item_id
   FROM test_item
   WHERE PATH @> (SELECT PATH
                  FROM test_item
                  WHERE item_id = NEW.issue_id))

  LOOP
    /* increment item defects statistics for concrete field */
    INSERT INTO statistics (s_counter, s_field, item_id) VALUES (1, defect_field, cur_id)
    ON CONFLICT (s_field, item_id)
      DO UPDATE SET s_counter = statistics.s_counter + 1;
    /* increment item defects statistics for total field */
    INSERT INTO statistics (s_counter, s_field, item_id) VALUES (1, defect_field_total, cur_id)
    ON CONFLICT (s_field, item_id)
      DO UPDATE SET s_counter = statistics.s_counter + 1;
  END LOOP;

  /* increment launch defects statistics for concrete field */
  INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, defect_field, cur_launch_id)
  ON CONFLICT (s_field, launch_id)
    DO UPDATE SET s_counter = statistics.s_counter + 1;
  /* increment launch defects statistics for total field */
  INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, defect_field_total, cur_launch_id)
  ON CONFLICT (s_field, launch_id)
    DO UPDATE SET s_counter = statistics.s_counter + 1;
  RETURN new;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER after_issue_insert
  AFTER INSERT
  ON issue
  FOR EACH ROW EXECUTE PROCEDURE increment_defect_statistics();


CREATE OR REPLACE FUNCTION update_defect_statistics()
  RETURNS TRIGGER AS $$
DECLARE   cur_id                 BIGINT;
  DECLARE defect_field           VARCHAR;
  DECLARE defect_field_total     VARCHAR;
  DECLARE defect_field_old       VARCHAR;
  DECLARE defect_field_old_total VARCHAR;
  DECLARE cur_launch_id          BIGINT;

BEGIN
  IF exists(SELECT 1
            FROM test_item AS s
              JOIN test_item AS s2 ON s.item_id = s2.parent_id
            WHERE s.item_id = new.issue_id)
  THEN RETURN new;
  END IF;

  IF old.issue_type = new.issue_type
  THEN RETURN new;
  END IF;

  cur_launch_id := (SELECT launch_id
                    FROM test_item
                    WHERE
                      test_item.item_id = new.issue_id);

  defect_field := (SELECT
                     concat('statistics$defects$', lower(public.issue_group.issue_group :: VARCHAR), '$', lower(public.issue_type.locator))
                   FROM issue_type
                     JOIN issue_group ON issue_type.issue_group_id = issue_group.issue_group_id
                   WHERE issue_type.id = new.issue_type);

  defect_field_old := (SELECT concat('statistics$defects$', lower(public.issue_group.issue_group :: VARCHAR), '$',
                                     lower(public.issue_type.locator))
                       FROM issue_type
                         JOIN issue_group ON issue_type.issue_group_id = issue_group.issue_group_id
                       WHERE issue_type.id = old.issue_type);

  defect_field_total := (SELECT concat('statistics$defects$', lower(public.issue_group.issue_group :: VARCHAR), '$total')
                         FROM issue_type
                           JOIN issue_group ON issue_type.issue_group_id = issue_group.issue_group_id
                         WHERE issue_type.id = new.issue_type);

  defect_field_old_total := (SELECT concat('statistics$defects$', lower(public.issue_group.issue_group :: VARCHAR), '$total')
                             FROM issue_type
                               JOIN issue_group ON issue_type.issue_group_id = issue_group.issue_group_id
                             WHERE issue_type.id = old.issue_type);

  FOR cur_id IN
  (SELECT item_id
   FROM test_item
   WHERE PATH @> (SELECT PATH
                  FROM test_item
                  WHERE item_id = NEW.issue_id))

  LOOP
    /* decrease item defects statistics for concrete field */
    UPDATE statistics
    SET s_counter = s_counter - 1
    WHERE s_field = defect_field_old AND statistics.item_id = cur_id;

    /* increment item defects statistics for concrete field */
    INSERT INTO statistics (s_counter, s_field, item_id) VALUES (1, defect_field, cur_id)
    ON CONFLICT (s_field, item_id)
      DO UPDATE SET s_counter = statistics.s_counter + 1;
  END LOOP;

  /* decrease item defects statistics for concrete field */
  UPDATE statistics
  SET s_counter = s_counter - 1
  WHERE s_field = defect_field_old AND launch_id = cur_launch_id;

  /* increment launch defects statistics for concrete field */
  INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, defect_field, cur_launch_id)
  ON CONFLICT (s_field, launch_id)
    DO UPDATE SET s_counter = statistics.s_counter + 1;

  /* decrease launch defects statistics for total field */
  UPDATE statistics
  SET s_counter = s_counter - 1
  WHERE s_field = defect_field_old_total AND launch_id = cur_launch_id;

  /* increment launch defects statistics for total field */
  INSERT INTO statistics (s_counter, s_field, launch_id) VALUES (1, defect_field_total, cur_launch_id)
  ON CONFLICT (s_field, launch_id)
    DO UPDATE SET s_counter = statistics.s_counter + 1;
  RETURN new;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER after_issue_update
  AFTER UPDATE
  ON issue
  FOR EACH ROW EXECUTE PROCEDURE update_defect_statistics();


CREATE OR REPLACE FUNCTION decrease_statistics()
  RETURNS TRIGGER AS $$
DECLARE   cur_launch_id         BIGINT;
  DECLARE cur_id                BIGINT;
  DECLARE cur_statistics_fields RECORD;
BEGIN

  cur_launch_id := (SELECT launch_id
                    FROM test_item
                    WHERE item_id = old.result_id);

  FOR cur_id IN
  (SELECT item_id
   FROM test_item
   WHERE PATH @> (SELECT PATH
                  FROM test_item
                  WHERE item_id = old.result_id))

  LOOP
    FOR cur_statistics_fields IN (SELECT
                                    s_field,
                                    s_counter
                                  FROM statistics
                                  WHERE item_id = old.result_id)
    LOOP
      UPDATE STATISTICS
      SET s_counter = s_counter - cur_statistics_fields.s_counter
      WHERE STATISTICS.s_field = cur_statistics_fields.s_field AND item_id = cur_id;
    END LOOP;
  END LOOP;

  FOR cur_statistics_fields IN (SELECT
                                  s_field,
                                  s_counter
                                FROM statistics
                                WHERE item_id = old.result_id)
  LOOP
    UPDATE statistics
    SET s_counter = s_counter - cur_statistics_fields.s_counter
    WHERE statistics.s_field = cur_statistics_fields.s_field AND launch_id = cur_launch_id;
  END LOOP;

  RETURN old;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER before_item_delete
  BEFORE DELETE
  ON test_item_results
  FOR EACH ROW EXECUTE PROCEDURE decrease_statistics();
