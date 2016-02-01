-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon Feb  1 15:59:14 2016
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS afisha;

--
-- Table: afisha
--
CREATE TABLE afisha (
  place1 text NULL,
  day text NULL,
  foto3 text NULL,
  color text NULL,
  foto2 text NULL,
  story_id bigint NOT NULL,
  subheader2 text NULL,
  header text NULL,
  issue_id bigint NOT NULL,
  subheader3 text NULL,
  place2 text NULL,
  foto1 text NULL,
  id integer NOT NULL auto_increment,
  time timestamp NOT NULL,
  subheader1 text NULL,
  event_time text NULL,
  block_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

SET foreign_key_checks=1;