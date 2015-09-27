-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sun Sep 27 03:23:38 2015
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS compare;

--
-- Table: compare
--
CREATE TABLE compare (
  text1 text NULL,
  title text NULL,
  text5 text NULL,
  text2 text NULL,
  block_id bigint NOT NULL,
  foto2 text NULL,
  text3 text NULL,
  name4 text NULL,
  text4 text NULL,
  name2 text NULL,
  name1 text NULL,
  issue_id bigint NOT NULL,
  foto1 text NULL,
  time timestamp NOT NULL,
  id integer NOT NULL auto_increment,
  foto3 text NULL,
  caption_id varchar(32) NOT NULL,
  foto5 text NULL,
  name3 text NULL,
  name5 text NULL,
  foto4 text NULL,
  story_id bigint NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

DROP TABLE IF EXISTS ecocols;

--
-- Table: ecocols
--
CREATE TABLE ecocols (
  block_id bigint NOT NULL,
  bar4 text NULL,
  text2 text NULL,
  num3 integer NULL,
  text1 text NULL,
  bar3 text NULL,
  text5 text NULL,
  bar2 text NULL,
  num1 integer NULL,
  num2 integer NULL,
  bar5 text NULL,
  bar1 text NULL,
  bar6 text NULL,
  num6 integer NULL,
  text4 text NULL,
  text3 text NULL,
  num5 integer NULL,
  num4 integer NULL,
  story_id bigint NOT NULL,
  time timestamp NOT NULL,
  id integer NOT NULL auto_increment,
  caption_id varchar(32) NOT NULL,
  header text NULL,
  issue_id bigint NOT NULL,
  text6 text NULL,
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
  bar3 text NULL,
  text1 text NULL,
  text5 text NULL,
  bar2 text NULL,
  num3 integer NULL,
  bar4 text NULL,
  text2 text NULL,
  block_id bigint NOT NULL,
  num2 integer NULL,
  bar5 text NULL,
  bar1 text NULL,
  num1 integer NULL,
  text3 text NULL,
  num6 integer NULL,
  bar6 text NULL,
  text4 text NULL,
  text7 text NULL,
  text6 text NULL,
  bar7 text NULL,
  issue_id bigint NOT NULL,
  num7 integer NULL,
  header text NULL,
  time timestamp NOT NULL,
  caption_id varchar(32) NOT NULL,
  id integer NOT NULL auto_increment,
  num5 integer NULL,
  num4 integer NULL,
  story_id bigint NOT NULL,
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
  block_id bigint NOT NULL,
  foto text NULL,
  title text NULL,
  news5 text NULL,
  title2 text NULL,
  news1 text NULL,
  time timestamp NOT NULL,
  id integer NOT NULL auto_increment,
  caption_id varchar(32) NOT NULL,
  story_id bigint NOT NULL,
  news3 text NULL,
  issue_id bigint NOT NULL,
  news4 text NULL,
  news2 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS teams_compare;

--
-- Table: teams_compare
--
CREATE TABLE teams_compare (
  score_l text NULL,
  num_r_02 text NULL,
  score_r text NULL,
  num_r_01 text NULL,
  block_id bigint NOT NULL,
  l_01 text NULL,
  num_l_02 text NULL,
  num_r_03 text NULL,
  foto2 text NULL,
  r_02 text NULL,
  r_03 text NULL,
  r_01 text NULL,
  num_l_01 text NULL,
  num_l_03 text NULL,
  issue_id bigint NOT NULL,
  foto1 text NULL,
  header text NULL,
  time timestamp NOT NULL,
  l_03 text NULL,
  caption_id varchar(32) NOT NULL,
  id integer NOT NULL auto_increment,
  l_02 text NULL,
  story_id bigint NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

SET foreign_key_checks=1;

