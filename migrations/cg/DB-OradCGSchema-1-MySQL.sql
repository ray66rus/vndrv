-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Fri Jan 15 01:44:37 2016
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS news_data;

--
-- Table: news_data
--
CREATE TABLE news_data (
  id integer NOT NULL auto_increment,
  last timestamp NOT NULL,
  captions text NULL,
  issue_id bigint NOT NULL,
  issue_name text NULL,
  issue_start datetime NULL,
  story_id bigint NOT NULL,
  story_name text NULL,
  block_id bigint NOT NULL,
  block_name text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX timestamp_idx (last),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id)
) COLLATE utf8_general_ci;

SET foreign_key_checks=1;

