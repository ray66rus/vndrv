-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sun Sep 27 02:21:11 2015
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS compare;

--
-- Table: compare
--
CREATE TABLE compare (
  story_id bigint NOT NULL,
  foto2 text NULL,
  name2 text NULL,
  foto3 text NULL,
  text1 text NULL,
  text4 text NULL,
  id integer NOT NULL auto_increment,
  text2 text NULL,
  foto1 text NULL,
  name5 text NULL,
  foto4 text NULL,
  block_id bigint NOT NULL,
  name1 text NULL,
  name4 text NULL,
  caption_id varchar(32) NOT NULL,
  title text NULL,
  text3 text NULL,
  issue_id bigint NOT NULL,
  text5 text NULL,
  foto5 text NULL,
  time timestamp NOT NULL,
  name3 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS ecocols;

--
-- Table: ecocols
--
CREATE TABLE ecocols (
  num6 integer NULL,
  bar5 text NULL,
  text6 text NULL,
  story_id bigint NOT NULL,
  bar3 text NULL,
  num2 integer NULL,
  text1 text NULL,
  text4 text NULL,
  id integer NOT NULL auto_increment,
  text2 text NULL,
  bar6 text NULL,
  num4 integer NULL,
  num5 integer NULL,
  block_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  bar2 text NULL,
  bar1 text NULL,
  bar4 text NULL,
  header text NULL,
  text3 text NULL,
  issue_id bigint NOT NULL,
  text5 text NULL,
  num1 integer NULL,
  time timestamp NOT NULL,
  num3 integer NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS ecorows;

--
-- Table: ecorows
--
CREATE TABLE ecorows (
  text3 text NULL,
  issue_id bigint NOT NULL,
  num3 integer NULL,
  time timestamp NOT NULL,
  num1 integer NULL,
  text5 text NULL,
  caption_id varchar(32) NOT NULL,
  block_id bigint NOT NULL,
  header text NULL,
  bar4 text NULL,
  bar2 text NULL,
  bar1 text NULL,
  id integer NOT NULL auto_increment,
  num5 integer NULL,
  num4 integer NULL,
  bar6 text NULL,
  text2 text NULL,
  num2 integer NULL,
  bar3 text NULL,
  num6 integer NULL,
  text6 text NULL,
  bar5 text NULL,
  story_id bigint NOT NULL,
  text4 text NULL,
  text1 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS news;

--
-- Table: news
--
CREATE TABLE news (
  caption_id varchar(32) NOT NULL,
  news3 text NULL,
  news5 text NULL,
  story_id bigint NOT NULL,
  block_id bigint NOT NULL,
  foto text NULL,
  title2 text NULL,
  title text NULL,
  issue_id bigint NOT NULL,
  id integer NOT NULL auto_increment,
  time timestamp NOT NULL,
  news2 text NULL,
  news1 text NULL,
  news4 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

DROP TABLE IF EXISTS teams_compare;

--
-- Table: teams_compare
--
CREATE TABLE teams_compare (
  foto1 text NULL,
  id integer NOT NULL auto_increment,
  score_l text NULL,
  num_l_02 text NULL,
  story_id bigint NOT NULL,
  foto2 text NULL,
  r_03 text NULL,
  l_01 text NULL,
  num_r_02 text NULL,
  score_r text NULL,
  l_03 text NULL,
  r_01 text NULL,
  time timestamp NOT NULL,
  l_02 text NULL,
  num_r_01 text NULL,
  issue_id bigint NOT NULL,
  num_r_03 text NULL,
  r_02 text NULL,
  header text NULL,
  num_l_03 text NULL,
  block_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  num_l_01 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

SET foreign_key_checks=1;

