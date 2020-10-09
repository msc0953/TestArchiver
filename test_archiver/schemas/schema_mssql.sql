
--INSERT INTO schema_updates(schema_version, applied_at, initial_update, applied_by) VALUES (2, GETDATE(), 1, '{applied_by}');

DROP TABLE schema_updates
CREATE TABLE schema_updates (
	[id] INTEGER PRIMARY KEY IDENTITY NOT NULL,
    [schema_version] int UNIQUE NOT NULL,
    [applied_at] [datetime] NOT NULL DEFAULT CURRENT_TIMESTAMP,
    [initial_update] int DEFAULT 0,
    [applied_by] text
	CONSTRAINT AK_schema_version UNIQUE([schema_version])
);

CREATE TABLE [test_series]
(
	[id] INTEGER PRIMARY KEY IDENTITY NOT NULL,
	[name] VARCHAR(30) NOT NULL, 
	[team] VARCHAR(30) NOT NULL
);

CREATE UNIQUE INDEX unique_test_series_idx ON test_series　(team, name);

--DROP TABLE test_run
CREATE TABLE [test_run] (
	[id] INTEGER PRIMARY KEY IDENTITY NOT NULL,
	[imported_at timestamp] [datetime] DEFAULT CURRENT_TIMESTAMP,
	[archived_using] VARCHAR(256),
	[archiver_version] VARCHAR(256),
	[generator] VARCHAR(256),
	[generated] [datetime] NOT NULL,
	[rpa] INTEGER,
	[dryrun] INTEGER,
	[ignored] INTEGER DEFAULT 0,
	[schema_version] int REFERENCES schema_updates([schema_version]) NOT NULL
);

CREATE TABLE [suite] (
    [id] INTEGER PRIMARY KEY IDENTITY NOT NULL,
    name VARCHAR(512),
    full_name VARCHAR(1024) NOT NULL,
    repository VARCHAR(128) NOT NULL
);
CREATE UNIQUE INDEX unique_suite_idx ON suite(repository, full_name);

--DROP TABLE suite_result
CREATE TABLE suite_result (
    suite_id int REFERENCES suite(id) ON DELETE CASCADE NOT NULL,
    test_run_id int REFERENCES test_run(id) ON DELETE CASCADE NOT NULL,
    status text,
    setup_status text,
    execution_status text,
    teardown_status text,
    start_time timestamp,
    elapsed int,
    setup_elapsed int,
    execution_elapsed int,
    teardown_elapsed int,
    fingerprint VARCHAR(512),
    setup_fingerprint text,
    execution_fingerprint text,
    teardown_fingerprint text,
    execution_path text,
    PRIMARY KEY (test_run_id, suite_id)
);
CREATE UNIQUE INDEX unique_suite_result_idx ON suite_result(start_time, fingerprint);


CREATE TABLE test_case (
    [id] INTEGER PRIMARY KEY IDENTITY NOT NULL,
    name VARCHAR(512) NOT NULL,
    full_name VARCHAR(512) NOT NULL,
    suite_id int REFERENCES suite(id) ON DELETE CASCADE NOT NULL
);
CREATE UNIQUE INDEX unique_test_case_idx ON test_case(full_name, suite_id);

CREATE TABLE test_result (
    test_id int REFERENCES test_case(id) ON DELETE CASCADE NOT NULL,
    test_run_id int REFERENCES test_run(id) ON DELETE CASCADE NOT NULL,
    status text,
    setup_status text,
    execution_status text,
    teardown_status text,
    start_time timestamp,
    elapsed int,
    setup_elapsed int,
    execution_elapsed int,
    teardown_elapsed int,
    critical int,
    fingerprint text,
    setup_fingerprint text,
    execution_fingerprint text,
    teardown_fingerprint text,
    execution_path text,
    PRIMARY KEY (test_run_id, test_id)
);

CREATE TABLE log_message (
	[id] INTEGER PRIMARY KEY IDENTITY NOT NULL,
    execution_path text,
    test_run_id int REFERENCES test_run(id) ON DELETE CASCADE NOT NULL,
    test_id int REFERENCES test_case(id) ON DELETE CASCADE,
    suite_id int REFERENCES suite(id) ON DELETE NO ACTION NOT NULL,
    timestamp timestamp,
    log_level text NOT NULL,
    message text
);

CREATE INDEX test_log_message_index ON log_message(test_run_id, suite_id, test_id);

CREATE TABLE suite_metadata (
    suite_id int REFERENCES suite(id) ON DELETE CASCADE NOT NULL,
    test_run_id int REFERENCES test_run(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(256) NOT NULL,
    value text,
    PRIMARY KEY (test_run_id, suite_id, name)
);

CREATE TABLE test_tag (
    test_id int REFERENCES test_case(id) ON DELETE CASCADE NOT NULL,
    test_run_id int REFERENCES test_run(id) ON DELETE CASCADE NOT NULL,
    tag VARCHAR(256) NOT NULL,
    PRIMARY KEY (test_run_id, test_id, tag)
);

CREATE TABLE keyword_tree (
    fingerprint VARCHAR(512) PRIMARY KEY,
    keyword text,
    library text,
    status text,
    arguments text
)

CREATE TABLE tree_hierarchy (
    fingerprint VARCHAR(512) REFERENCES keyword_tree(fingerprint),
    subtree VARCHAR(512) REFERENCES keyword_tree(fingerprint),
    call_index VARCHAR(512),
    PRIMARY KEY (fingerprint, subtree, call_index)
);

CREATE TABLE keyword_statistics (
    test_run_id int REFERENCES test_run(id) ON DELETE CASCADE NOT NULL,
    fingerprint VARCHAR(512) REFERENCES keyword_tree(fingerprint),
    calls int,
    max_execution_time int,
    min_execution_time int,
    cumulative_execution_time int,
    max_call_depth int,
    PRIMARY KEY (test_run_id, fingerprint)
);