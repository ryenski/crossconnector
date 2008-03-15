-- PostgreSQL schema
-- for FileColumn Tests
--

CREATE TABLE entries (
  id                  serial primary key NOT null,
  image               varchar(200) default NULL,
  file                varchar(200) NOT NULL
);

CREATE TABLE movies (
  id                  serial primary key NOT null,
  movie               varchar(200) default NULL
);