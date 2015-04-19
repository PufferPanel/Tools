-- Remove existing database and create new
DROP DATABASE IF EXISTS `pufferpanel`;
CREATE DATABASE `pufferpanel` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci;
USE `pufferpanel`;

-- Create the tables needed
CREATE TABLE `acp_settings` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `setting_ref` varchar(25) NOT NULL,
  `setting_val` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_ref_unique` (`setting_ref`)
) ENGINE=InnoDB;

CREATE TABLE `downloads` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `server` char(36) NOT NULL,
  `token` char(32) NOT NULL,
  `path` varchar(5000) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MEMORY;

CREATE TABLE `locations` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `short` varchar(10) NOT NULL,
  `long` varchar(500) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `short_unique` (`short`)
) ENGINE=InnoDB;

CREATE TABLE `plugins` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `hash` char(36) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `variables` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug_unique` (`slug`)
) ENGINE=InnoDB;

CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `username` varchar(50),
  `email` varchar(255) NOT NULL,
  `password` text DEFAULT NULL,
  `language` char(2) NOT NULL DEFAULT 'en',
  `register_time` int(15) unsigned NOT NULL,
  `session_id` char(12) DEFAULT '',
  `session_ip` varchar(50) DEFAULT '',
  `root_admin` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `notify_login_s` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `notify_login_f` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `use_totp` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `totp_secret` char(16),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid_unique` (`uuid`),
  UNIQUE KEY `email_unique` (`email`)
) ENGINE=InnoDB;

CREATE TABLE `account_change` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned,
  `type` varchar(50) NOT NULL DEFAULT '',
  `content` mediumtext NOT NULL,
  `key` mediumtext NOT NULL,
  `time` int(15) unsigned NOT NULL,
  `verified` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `FK_account_change_users` (`user_id`),
  CONSTRAINT `FK_account_change_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `actions_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `priority` tinyint(1) NOT NULL,
  `viewable` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `user` int(10) unsigned DEFAULT NULL,
  `time` int(15) unsigned NOT NULL,
  `ip` varchar(100) NOT NULL,
  `url` text NOT NULL,
  `action` varchar(100) NOT NULL,
  `desc` mediumtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_actions_log_users` (`user`),
  CONSTRAINT `FK_actions_log_users` FOREIGN KEY (`user`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `nodes` (
  `id` mediumint(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(15) NOT NULL,
  `location` mediumint(8) unsigned NOT NULL,
  `allocate_memory` mediumint(8) unsigned NOT NULL,
  `allocate_disk` int(10) unsigned NOT NULL,
  `fqdn` varchar(255) NOT NULL,
  `ip` varchar(45) NOT NULL,
  `daemon_secret` char(36) DEFAULT NULL,
  `daemon_listen` smallint(5) unsigned DEFAULT '5656',
  `daemon_console` smallint(5) unsigned DEFAULT '5657',
  `daemon_upload` smallint(5) unsigned DEFAULT '5658',
  `daemon_sftp` smallint(5) unsigned DEFAULT '22',
  `daemon_base_dir` varchar(200) DEFAULT '/home/',
  `ips` mediumtext NOT NULL,
  `ports` mediumtext NOT NULL,
  `public` tinyint(1) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `FK_nodes_locations` (`location`),
  CONSTRAINT `FK_nodes_locations` FOREIGN KEY (`location`) REFERENCES `locations` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `servers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hash` char(36) NOT NULL,
  `daemon_secret` char(36) NOT NULL,
  `node` mediumint(8) unsigned NOT NULL,
  `name` varchar(200) NOT NULL,
  `plugin` mediumint(10) unsigned NOT NULL,
  `pack` varchar(100) NOT NULL DEFAULT '',
  `daemon_startup` text,
  `daemon_variables` text,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `owner_id` int(10) unsigned NOT NULL,
  `max_ram` smallint(5) unsigned NOT NULL,
  `disk_space` int(10) unsigned NOT NULL,
  `cpu_limit` smallint(6) unsigned DEFAULT NULL,
  `date_added` int(10) unsigned NOT NULL,
  `server_ip` varchar(45) NOT NULL,
  `server_port` smallint(5) unsigned NOT NULL,
  `sftp_user` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_servers_users` (`owner_id`),
  KEY `FK_servers_nodes` (`node`),
  KEY `FK_servers_plugin` (`plugin`),
  CONSTRAINT `FK_servers_plugin` FOREIGN KEY (`plugin`) REFERENCES `plugins` (`id`),
  CONSTRAINT `FK_servers_nodes` FOREIGN KEY (`node`) REFERENCES `nodes` (`id`),
  CONSTRAINT `FK_servers_users` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`)
 ) ENGINE=InnoDB;

CREATE TABLE `permissions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `server` int(10) unsigned NOT NULL,
  `permission` varchar(200) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `FK_permissions_users` (`user`),
  KEY `FK_permissions_servers` (`server`),
  CONSTRAINT `FK_permissions_servers` FOREIGN KEY (`server`) REFERENCES `servers` (`id`),
  CONSTRAINT `FK_permissions_users` FOREIGN KEY (`user`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;

CREATE TABLE `subusers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `server` int(10) unsigned NOT NULL,
  `daemon_secret` char(36) NOT NULL,
  `daemon_permissions` mediumtext,
  `pending` tinyint(1) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_server_key` (`user`, `server`),
  CONSTRAINT `FK_subusers_user` FOREIGN KEY (`user`) REFERENCES `users` (`id`),
  CONSTRAINT `FK_subusers_server` FOREIGN KEY (`server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB;

-- Insert all default data
INSERT INTO `plugins` VALUES
	(1, '37d8949d-5da2-4390-a28f-27ac1babc4da', 'minecraft', 'Minecraft', 'Minecraft is a game about breaking and placing blocks. At first, people built structures to protect against nocturnal monsters, but as the game grew players worked together to create wonderful, imaginative things. This version of the plugin is ment for versions of the game <strong>greater than 1.7.0</strong>.', '{}'),
	(2, 'b4b90feb-6adb-499c-a9f8-09b6e80c9d16', 'minecraft-pre', 'Minecraft (pre 1.7)', 'Minecraft is a game about breaking and placing blocks. At first, people built structures to protect against nocturnal monsters, but as the game grew players worked together to create wonderful, imaginative things. This version of the plugin is ment for versions of the game <strong>less than 1.7.0</strong>.', '{}'),
	(3, '64a8fe48-0b69-4e8a-96c4-14c60309c6c1', 'bungeecord', 'BungeeCord', 'For a long time, Minecraft server owners have had a dream that encompasses a free, easy, and reliable way to connect multiple Minecraft servers together. BungeeCord is the answer to said dream. Whether you are a small server wishing to string multiple game-modes together, or the owner of the ShotBow Network, BungeeCord is the ideal solution for you. With the help of BungeeCord, you will be able to unlock your community\'s full potential.', '{}');
