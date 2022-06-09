CREATE TABLE IF NOT EXISTS `codes` (
  `code` varchar(50) NOT NULL DEFAULT '',
  `packagename` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` int(100) NOT NULL DEFAULT 0,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
