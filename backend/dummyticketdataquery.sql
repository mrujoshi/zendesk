PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users VALUES(1,'Aarav Patel','Employee','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(2,'Aditi Sharma','Manager','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(3,'Rohan Gupta','Support','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(4,'Sanya Verma','Finance','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(5,'Vikram Malhotra','HR','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(6,'Ananya Deshmukh','Operations','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(7,'Karan Mehta','Developer','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(8,'Pooja Kulkarni','QA','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(9,'Siddharth Rao','DevOps','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO users VALUES(10,'Neha Joshi','Product','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
CREATE TABLE clients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO clients VALUES(1,'Acme Corp','support@acme.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(2,'Globex International','it@globex.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(3,'Initech Systems','help@initech.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(4,'Umbrella Health','contact@umbrella.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(5,'Stark Industries','support@stark.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(6,'Wayne Enterprises','helpdesk@wayne.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(7,'Cyberdyne AI','ops@cyberdyne.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(8,'Soylent Corp','client@soylent.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(9,'Massive Dynamic','contact@massivedynamic.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
INSERT INTO clients VALUES(10,'Hooli Cloud','billing@hooli.com','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','2026-11-21 09:04:01');
CREATE TABLE agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('admin', 'agent')),
    password_hash TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO agents VALUES(1,'Admin Asha','asha@demo.com','admin','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(2,'Priya Agent','priya@demo.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(3,'Rahul Agent','rahul@demo.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(4,'Mrudula','mrudula@support.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(5,'Monali','monali@support.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(6,'Mrunnayee','mrunnayee@support.com','admin','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(7,'Amit Joshi','amit@support.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(8,'Sneha Patil','sneha@support.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(9,'Kunal Shinde','kunal@support.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
INSERT INTO agents VALUES(10,'Divya Nair','divya@support.com','agent','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',1,'2026-11-21 09:04:01');
CREATE TABLE statuses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);
INSERT INTO statuses VALUES(1,'open');
INSERT INTO statuses VALUES(2,'pending');
INSERT INTO statuses VALUES(3,'solved');
INSERT INTO statuses VALUES(4,'closed');
INSERT INTO statuses VALUES(5,'sla_breached');
INSERT INTO statuses VALUES(6,'escalated');
CREATE TABLE priorities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);
INSERT INTO priorities VALUES(1,'low');
INSERT INTO priorities VALUES(2,'normal');
INSERT INTO priorities VALUES(3,'high');
INSERT INTO priorities VALUES(4,'urgent');
CREATE TABLE tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'pending', 'solved', 'closed', 'sla_breached', 'escalated')),
    priority TEXT NOT NULL DEFAULT 'normal' CHECK(priority IN ('low', 'normal', 'high', 'urgent')),
    client_id INTEGER NOT NULL,
    agent_id INTEGER,
    is_escalated INTEGER NOT NULL DEFAULT 0 CHECK(is_escalated IN (0, 1)),
    attachment_path TEXT,
    due_at TIMESTAMP,
    solved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL
);
INSERT INTO tickets VALUES(1,'SSO login failure with Okta integration','Users in EU region cannot authenticate via SAML 2.0; receiving ''Invalid SAML response'' error on callback.','open','urgent',1,NULL,0,NULL,'2026-11-21T09:58:01.165217+00:00',NULL,'2026-11-21T08:58:01.165217+00:00','2026-11-21T09:01:01.165217+00:00');
INSERT INTO tickets VALUES(2,'Payment gateway returned error 502 on renewal','Annual subscription failed during automated Stripe charge. Need invoice reissued.','open','urgent',2,7,0,NULL,'2026-11-21T09:40:15.565217+00:00',NULL,'2026-11-21T08:40:15.565217+00:00','2026-11-21T08:52:08.365217+00:00');
INSERT INTO tickets VALUES(3,'Need bulk export of customer contact records','Please provide a complete CSV dump of our company contacts created before Q3.','open','urgent',3,4,0,NULL,'2026-11-21T09:22:29.965217+00:00',NULL,'2026-11-21T08:22:29.965217+00:00','2026-11-21T08:43:15.565217+00:00');
INSERT INTO tickets VALUES(4,'Webhook delivery latency exceeding 5 seconds','Event callbacks for ticket.updated are delayed by up to 10 minutes during peak hours.','open','urgent',4,9,0,NULL,'2026-11-21T09:52:44.365217+00:00',NULL,'2026-11-21T08:52:44.365217+00:00','2026-11-21T08:58:22.765217+00:00');
INSERT INTO tickets VALUES(5,'Two-factor authentication code not received via SMS','Team members on Vodafone network in Mumbai report OTP SMS messages are not arriving.','open','urgent',5,7,0,NULL,'2026-11-21T09:34:58.765217+00:00',NULL,'2026-11-21T08:34:58.765217+00:00','2026-11-21T08:49:29.965217+00:00');
INSERT INTO tickets VALUES(6,'Invoice for October missing tax deduction breakdown','The latest consolidated invoice does not show the GST breakdown required by our accounting department.','open','urgent',6,2,0,NULL,'2026-11-21T09:17:13.165217+00:00',NULL,'2026-11-21T08:17:13.165217+00:00','2026-11-21T08:40:37.165217+00:00');
INSERT INTO tickets VALUES(7,'Feature Request: Add dark mode toggle in portal','Would greatly appreciate a system-level dark theme for our agents working night shifts.','open','urgent',7,9,0,NULL,'2026-11-21T09:47:27.565217+00:00',NULL,'2026-11-21T08:47:27.565217+00:00','2026-11-21T08:55:44.365217+00:00');
INSERT INTO tickets VALUES(8,'API rate limit reached unexpectedly on /tickets endpoint','Our integration script received 429 Too Many Requests despite staying within the 100 req/min limit.','open','urgent',8,4,0,NULL,'2026-11-21T09:29:41.965217+00:00',NULL,'2026-11-21T08:29:41.965217+00:00','2026-11-21T08:46:51.565217+00:00');
INSERT INTO tickets VALUES(9,'Dashboard widget charts failing to load on Safari','Analytics graphs render blank in Safari 17.2, though they display properly in Chrome and Firefox.','open','urgent',9,2,0,NULL,'2026-11-21T09:11:56.365217+00:00',NULL,'2026-11-21T08:11:56.365217+00:00','2026-11-21T08:37:58.765217+00:00');
INSERT INTO tickets VALUES(10,'Unable to invite new team members with Admin role','When sending invite email to new supervisor, the role dropdown resets to Agent.','open','urgent',10,7,0,NULL,'2026-11-21T09:42:10.765217+00:00',NULL,'2026-11-21T08:42:10.765217+00:00','2026-11-21T08:53:05.965217+00:00');
INSERT INTO tickets VALUES(11,'SSL certificate warning on custom domain setup','Visiting support.acme.com shows NET::ERR_CERT_COMMON_NAME_INVALID error.','open','urgent',1,NULL,0,NULL,'2026-11-21T09:24:25.165217+00:00',NULL,'2026-11-21T08:24:25.165217+00:00','2026-11-21T08:44:13.165217+00:00');
INSERT INTO tickets VALUES(12,'Password reset email link expired immediately','The link sent to our director expired within 2 minutes instead of the documented 24 hours.','open','urgent',2,7,0,NULL,'2026-11-21T08:37:01.165217+00:00',NULL,'2026-11-21T07:37:01.165217+00:00','2026-11-21T08:20:31.165217+00:00');
INSERT INTO tickets VALUES(13,'Slow query response on ticket search with multiple tags','Full-text search queries take over 4 seconds when searching with 3 or more tags.','open','high',3,4,0,NULL,'2026-11-21T11:15:32.365217+00:00',NULL,'2026-11-21T07:15:32.365217+00:00','2026-11-21T08:09:46.765217+00:00');
INSERT INTO tickets VALUES(14,'Need SOC2 Type II compliance report for annual audit','Our security team requires your latest SOC2 compliance summary for our vendor review.','open','high',4,9,0,NULL,'2026-11-21T10:04:29.965217+00:00',NULL,'2026-11-21T06:04:29.965217+00:00','2026-11-21T07:34:15.565217+00:00');
INSERT INTO tickets VALUES(15,'CSV import failing with invalid character encoding','Importing user list fails on row 142 due to non-ASCII accented characters in customer names.','open','high',5,7,0,NULL,'2026-11-21T12:05:27.565217+00:00',NULL,'2026-11-21T08:05:27.565217+00:00','2026-11-21T08:34:44.365217+00:00');
INSERT INTO tickets VALUES(16,'Email notification not sent when ticket is assigned','Agent assignment notifications stopped firing around 09:00 UTC this morning.','open','high',6,2,0,NULL,'2026-11-21T10:54:25.165217+00:00',NULL,'2026-11-21T06:54:25.165217+00:00','2026-11-21T07:59:13.165217+00:00');
INSERT INTO tickets VALUES(17,'Mobile responsive view breaks on conversation thread','Long code snippets in message threads overflow the viewport on iOS Safari.','open','high',7,9,0,NULL,'2026-11-21T09:43:22.765217+00:00',NULL,'2026-11-21T05:43:22.765217+00:00','2026-11-21T07:23:41.965217+00:00');
INSERT INTO tickets VALUES(18,'Session timeout logging agents out every 10 minutes','Staff are repeatedly prompted to log in while drafting responses to customers.','open','high',8,4,0,NULL,'2026-11-21T11:44:20.365217+00:00',NULL,'2026-11-21T07:44:20.365217+00:00','2026-11-21T08:24:10.765217+00:00');
INSERT INTO tickets VALUES(19,'Cannot download PDF attachments larger than 10MB','Attempting to download architecture diagrams returns HTTP 413 Payload Too Large.','open','high',9,2,0,NULL,'2026-11-21T10:33:17.965217+00:00',NULL,'2026-11-21T06:33:17.965217+00:00','2026-11-21T07:48:39.565217+00:00');
INSERT INTO tickets VALUES(20,'Requesting sandbox environment reset for QA testing','Please flush the staging database and seed fresh demo tickets for our upcoming demo.','open','high',10,7,0,NULL,'2026-11-21T12:34:15.565217+00:00',NULL,'2026-11-21T08:34:15.565217+00:00','2026-11-21T08:49:08.365217+00:00');
INSERT INTO tickets VALUES(21,'SSO login failure with Okta integration (Batch #2)','Users in EU region cannot authenticate via SAML 2.0; receiving ''Invalid SAML response'' error on callback.','open','high',1,NULL,0,NULL,'2026-11-21T11:23:13.165217+00:00',NULL,'2026-11-21T07:23:13.165217+00:00','2026-11-21T08:13:37.165217+00:00');
INSERT INTO tickets VALUES(22,'Payment gateway returned error 502 on renewal (Batch #2)','Annual subscription failed during automated Stripe charge. Need invoice reissued.','open','high',2,7,0,NULL,'2026-11-21T10:12:10.765217+00:00',NULL,'2026-11-21T06:12:10.765217+00:00','2026-11-21T07:38:05.965217+00:00');
INSERT INTO tickets VALUES(23,'Need bulk export of customer contact records (Batch #2)','Please provide a complete CSV dump of our company contacts created before Q3.','open','high',3,4,0,NULL,'2026-11-21T12:13:08.365217+00:00',NULL,'2026-11-21T08:13:08.365217+00:00','2026-11-21T08:38:34.765217+00:00');
INSERT INTO tickets VALUES(24,'Webhook delivery latency exceeding 5 seconds (Batch #2)','Event callbacks for ticket.updated are delayed by up to 10 minutes during peak hours.','open','high',4,9,0,NULL,'2026-11-21T08:25:01.165217+00:00',NULL,'2026-11-21T04:25:01.165217+00:00','2026-11-21T06:25:01.165217+00:00');
INSERT INTO tickets VALUES(25,'Two-factor authentication code not received via SMS (Batch #2)','Team members on Vodafone network in Mumbai report OTP SMS messages are not arriving.','open','high',5,7,0,NULL,'2026-11-21T09:51:03.565217+00:00',NULL,'2026-11-21T05:51:03.565217+00:00','2026-11-21T07:27:32.365217+00:00');
INSERT INTO tickets VALUES(26,'Invoice for October missing tax deduction breakdown (Batch #2)','The latest consolidated invoice does not show the GST breakdown required by our accounting department.','open','high',6,2,0,NULL,'2026-11-21T11:52:01.165217+00:00',NULL,'2026-11-21T07:52:01.165217+00:00','2026-11-21T08:28:01.165217+00:00');
INSERT INTO tickets VALUES(27,'Feature Request: Add dark mode toggle in portal (Batch #2)','Would greatly appreciate a system-level dark theme for our agents working night shifts.','open','high',7,9,0,NULL,'2026-11-21T10:40:58.765217+00:00',NULL,'2026-11-21T06:40:58.765217+00:00','2026-11-21T07:52:29.965217+00:00');
INSERT INTO tickets VALUES(28,'API rate limit reached unexpectedly on /tickets endpoint (Batch #2)','Our integration script received 429 Too Many Requests despite staying within the 100 req/min limit.','open','high',8,4,0,NULL,'2026-11-21T09:29:56.365217+00:00',NULL,'2026-11-21T05:29:56.365217+00:00','2026-11-21T07:16:58.765217+00:00');
INSERT INTO tickets VALUES(29,'Dashboard widget charts failing to load on Safari (Batch #2)','Analytics graphs render blank in Safari 17.2, though they display properly in Chrome and Firefox.','open','high',9,2,0,NULL,'2026-11-21T11:30:53.965217+00:00',NULL,'2026-11-21T07:30:53.965217+00:00','2026-11-21T08:17:27.565217+00:00');
INSERT INTO tickets VALUES(30,'Unable to invite new team members with Admin role (Batch #2)','When sending invite email to new supervisor, the role dropdown resets to Agent.','open','high',10,7,0,NULL,'2026-11-21T10:19:51.565217+00:00',NULL,'2026-11-21T06:19:51.565217+00:00','2026-11-21T07:41:56.365217+00:00');
INSERT INTO tickets VALUES(31,'SSL certificate warning on custom domain setup (Batch #2)','Visiting support.acme.com shows NET::ERR_CERT_COMMON_NAME_INVALID error.','open','high',1,NULL,0,NULL,'2026-11-21T12:20:49.165217+00:00',NULL,'2026-11-21T08:20:49.165217+00:00','2026-11-21T08:42:25.165217+00:00');
INSERT INTO tickets VALUES(32,'Password reset email link expired immediately (Batch #2)','The link sent to our director expired within 2 minutes instead of the documented 24 hours.','open','high',2,7,0,NULL,'2026-11-21T11:09:46.765217+00:00',NULL,'2026-11-21T07:09:46.765217+00:00','2026-11-21T08:06:53.965217+00:00');
INSERT INTO tickets VALUES(33,'Slow query response on ticket search with multiple tags (Batch #2)','Full-text search queries take over 4 seconds when searching with 3 or more tags.','open','high',3,4,0,NULL,'2026-11-21T09:58:44.365217+00:00',NULL,'2026-11-21T05:58:44.365217+00:00','2026-11-21T07:31:22.765217+00:00');
INSERT INTO tickets VALUES(34,'Need SOC2 Type II compliance report for annual audit (Batch #2)','Our security team requires your latest SOC2 compliance summary for our vendor review.','open','high',4,9,0,NULL,'2026-11-21T11:59:41.965217+00:00',NULL,'2026-11-21T07:59:41.965217+00:00','2026-11-21T08:31:51.565217+00:00');
INSERT INTO tickets VALUES(35,'CSV import failing with invalid character encoding (Batch #2)','Importing user list fails on row 142 due to non-ASCII accented characters in customer names.','open','normal',5,7,0,NULL,'2026-11-21T19:31:51.565217+00:00',NULL,'2026-11-20T19:31:51.565217+00:00','2026-11-20T21:31:51.565217+00:00');
INSERT INTO tickets VALUES(36,'Email notification not sent when ticket is assigned (Batch #2)','Agent assignment notifications stopped firing around 09:00 UTC this morning.','pending','normal',6,2,0,NULL,'2026-11-21T08:43:01.165217+00:00',NULL,'2026-11-20T08:43:01.165217+00:00','2026-11-20T10:43:01.165217+00:00');
INSERT INTO tickets VALUES(37,'Mobile responsive view breaks on conversation thread (Batch #2)','Long code snippets in message threads overflow the viewport on iOS Safari.','pending','normal',7,9,0,NULL,'2026-11-22T00:31:22.765217+00:00',NULL,'2026-11-21T00:31:22.765217+00:00','2026-11-21T02:31:22.765217+00:00');
INSERT INTO tickets VALUES(38,'Session timeout logging agents out every 10 minutes (Batch #2)','Staff are repeatedly prompted to log in while drafting responses to customers.','pending','normal',8,4,0,NULL,'2026-11-21T17:25:08.365217+00:00',NULL,'2026-11-20T17:25:08.365217+00:00','2026-11-20T19:25:08.365217+00:00');
INSERT INTO tickets VALUES(39,'Cannot download PDF attachments larger than 10MB (Batch #2)','Attempting to download architecture diagrams returns HTTP 413 Payload Too Large.','pending','normal',9,2,0,NULL,'2026-11-22T05:30:53.965217+00:00',NULL,'2026-11-21T05:30:53.965217+00:00','2026-11-21T07:17:27.565217+00:00');
INSERT INTO tickets VALUES(40,'Requesting sandbox environment reset for QA testing (Batch #2)','Please flush the staging database and seed fresh demo tickets for our upcoming demo.','pending','normal',10,7,0,NULL,'2026-11-21T22:24:39.565217+00:00',NULL,'2026-11-20T22:24:39.565217+00:00','2026-11-21T00:24:39.565217+00:00');
INSERT INTO tickets VALUES(41,'SSO login failure with Okta integration (Batch #3)','Users in EU region cannot authenticate via SAML 2.0; receiving ''Invalid SAML response'' error on callback.','pending','normal',1,NULL,0,NULL,'2026-11-21T15:18:25.165217+00:00',NULL,'2026-11-20T15:18:25.165217+00:00','2026-11-20T17:18:25.165217+00:00');
INSERT INTO tickets VALUES(42,'Payment gateway returned error 502 on renewal (Batch #3)','Annual subscription failed during automated Stripe charge. Need invoice reissued.','pending','normal',2,7,0,NULL,'2026-11-22T03:24:10.765217+00:00',NULL,'2026-11-21T03:24:10.765217+00:00','2026-11-21T05:24:10.765217+00:00');
INSERT INTO tickets VALUES(43,'Need bulk export of customer contact records (Batch #3)','Please provide a complete CSV dump of our company contacts created before Q3.','pending','normal',3,4,0,NULL,'2026-11-21T20:17:56.365217+00:00',NULL,'2026-11-20T20:17:56.365217+00:00','2026-11-20T22:17:56.365217+00:00');
INSERT INTO tickets VALUES(44,'Webhook delivery latency exceeding 5 seconds (Batch #3)','Event callbacks for ticket.updated are delayed by up to 10 minutes during peak hours.','pending','normal',4,9,0,NULL,'2026-11-21T13:11:41.965217+00:00',NULL,'2026-11-20T13:11:41.965217+00:00','2026-11-20T15:11:41.965217+00:00');
INSERT INTO tickets VALUES(45,'Two-factor authentication code not received via SMS (Batch #3)','Team members on Vodafone network in Mumbai report OTP SMS messages are not arriving.','pending','normal',5,7,0,NULL,'2026-11-22T01:17:27.565217+00:00',NULL,'2026-11-21T01:17:27.565217+00:00','2026-11-21T03:17:27.565217+00:00');
INSERT INTO tickets VALUES(46,'Invoice for October missing tax deduction breakdown (Batch #3)','The latest consolidated invoice does not show the GST breakdown required by our accounting department.','pending','normal',6,2,0,NULL,'2026-11-21T18:11:13.165217+00:00',NULL,'2026-11-20T18:11:13.165217+00:00','2026-11-20T20:11:13.165217+00:00');
INSERT INTO tickets VALUES(47,'Feature Request: Add dark mode toggle in portal (Batch #3)','Would greatly appreciate a system-level dark theme for our agents working night shifts.','pending','normal',7,9,0,NULL,'2026-11-22T06:16:58.765217+00:00',NULL,'2026-11-21T06:16:58.765217+00:00','2026-11-21T07:40:29.965217+00:00');
INSERT INTO tickets VALUES(48,'API rate limit reached unexpectedly on /tickets endpoint (Batch #3)','Our integration script received 429 Too Many Requests despite staying within the 100 req/min limit.','pending','normal',8,4,0,NULL,'2026-11-21T08:31:01.165217+00:00',NULL,'2026-11-20T08:31:01.165217+00:00','2026-11-20T10:31:01.165217+00:00');
INSERT INTO tickets VALUES(49,'Dashboard widget charts failing to load on Safari (Batch #3)','Analytics graphs render blank in Safari 17.2, though they display properly in Chrome and Firefox.','pending','normal',9,2,0,NULL,'2026-11-21T16:04:29.965217+00:00',NULL,'2026-11-20T16:04:29.965217+00:00','2026-11-20T18:04:29.965217+00:00');
INSERT INTO tickets VALUES(50,'Unable to invite new team members with Admin role (Batch #3)','When sending invite email to new supervisor, the role dropdown resets to Agent.','pending','normal',10,7,0,NULL,'2026-11-22T04:10:15.565217+00:00',NULL,'2026-11-21T04:10:15.565217+00:00','2026-11-21T06:10:15.565217+00:00');
INSERT INTO tickets VALUES(51,'SSL certificate warning on custom domain setup (Batch #3)','Visiting support.acme.com shows NET::ERR_CERT_COMMON_NAME_INVALID error.','pending','normal',1,NULL,0,NULL,'2026-11-21T21:04:01.165217+00:00',NULL,'2026-11-20T21:04:01.165217+00:00','2026-11-20T23:04:01.165217+00:00');
INSERT INTO tickets VALUES(52,'Password reset email link expired immediately (Batch #3)','The link sent to our director expired within 2 minutes instead of the documented 24 hours.','pending','normal',2,7,0,NULL,'2026-11-21T13:57:46.765217+00:00',NULL,'2026-11-20T13:57:46.765217+00:00','2026-11-20T15:57:46.765217+00:00');
INSERT INTO tickets VALUES(53,'Slow query response on ticket search with multiple tags (Batch #3)','Full-text search queries take over 4 seconds when searching with 3 or more tags.','pending','normal',3,4,0,NULL,'2026-11-22T02:03:32.365217+00:00',NULL,'2026-11-21T02:03:32.365217+00:00','2026-11-21T04:03:32.365217+00:00');
INSERT INTO tickets VALUES(54,'Need SOC2 Type II compliance report for annual audit (Batch #3)','Our security team requires your latest SOC2 compliance summary for our vendor review.','pending','normal',4,9,0,NULL,'2026-11-21T18:57:17.965217+00:00',NULL,'2026-11-20T18:57:17.965217+00:00','2026-11-20T20:57:17.965217+00:00');
INSERT INTO tickets VALUES(55,'CSV import failing with invalid character encoding (Batch #3)','Importing user list fails on row 142 due to non-ASCII accented characters in customer names.','pending','normal',5,7,0,NULL,'2026-11-21T11:51:03.565217+00:00',NULL,'2026-11-20T11:51:03.565217+00:00','2026-11-20T13:51:03.565217+00:00');
INSERT INTO tickets VALUES(56,'Email notification not sent when ticket is assigned (Batch #3)','Agent assignment notifications stopped firing around 09:00 UTC this morning.','pending','normal',6,2,0,NULL,'2026-11-21T23:56:49.165217+00:00',NULL,'2026-11-20T23:56:49.165217+00:00','2026-11-21T01:56:49.165217+00:00');
INSERT INTO tickets VALUES(57,'Mobile responsive view breaks on conversation thread (Batch #3)','Long code snippets in message threads overflow the viewport on iOS Safari.','pending','normal',7,9,0,NULL,'2026-11-21T16:50:34.765217+00:00',NULL,'2026-11-20T16:50:34.765217+00:00','2026-11-20T18:50:34.765217+00:00');
INSERT INTO tickets VALUES(58,'Session timeout logging agents out every 10 minutes (Batch #3)','Staff are repeatedly prompted to log in while drafting responses to customers.','pending','normal',8,4,0,NULL,'2026-11-22T04:56:20.365217+00:00',NULL,'2026-11-21T04:56:20.365217+00:00','2026-11-21T06:56:20.365217+00:00');
INSERT INTO tickets VALUES(59,'Cannot download PDF attachments larger than 10MB (Batch #3)','Attempting to download architecture diagrams returns HTTP 413 Payload Too Large.','pending','normal',9,2,0,NULL,'2026-11-21T21:50:05.965217+00:00',NULL,'2026-11-20T21:50:05.965217+00:00','2026-11-20T23:50:05.965217+00:00');
INSERT INTO tickets VALUES(60,'Requesting sandbox environment reset for QA testing (Batch #3)','Please flush the staging database and seed fresh demo tickets for our upcoming demo.','pending','normal',10,7,0,NULL,'2026-11-21T08:49:01.165217+00:00',NULL,'2026-11-20T08:49:01.165217+00:00','2026-11-20T10:49:01.165217+00:00');
INSERT INTO tickets VALUES(61,'SSO login failure with Okta integration (Batch #4)','Users in EU region cannot authenticate via SAML 2.0; receiving ''Invalid SAML response'' error on callback.','solved','normal',1,2,0,NULL,'2026-11-20T09:04:01.165217+00:00','2026-11-19T11:04:01.165217+00:00','2026-11-19T09:04:01.165217+00:00','2026-11-19T11:04:01.165217+00:00');
INSERT INTO tickets VALUES(62,'Payment gateway returned error 502 on renewal (Batch #4)','Annual subscription failed during automated Stripe charge. Need invoice reissued.','solved','normal',2,7,0,NULL,'2026-11-20T10:16:01.165217+00:00','2026-11-19T12:16:01.165217+00:00','2026-11-19T10:16:01.165217+00:00','2026-11-19T12:16:01.165217+00:00');
INSERT INTO tickets VALUES(63,'Need bulk export of customer contact records (Batch #4)','Please provide a complete CSV dump of our company contacts created before Q3.','solved','normal',3,4,0,NULL,'2026-11-20T11:28:01.165217+00:00','2026-11-19T13:28:01.165217+00:00','2026-11-19T11:28:01.165217+00:00','2026-11-19T13:28:01.165217+00:00');
INSERT INTO tickets VALUES(64,'Webhook delivery latency exceeding 5 seconds (Batch #4)','Event callbacks for ticket.updated are delayed by up to 10 minutes during peak hours.','solved','normal',4,9,0,NULL,'2026-11-20T12:40:01.165217+00:00','2026-11-19T14:40:01.165217+00:00','2026-11-19T12:40:01.165217+00:00','2026-11-19T14:40:01.165217+00:00');
INSERT INTO tickets VALUES(65,'Two-factor authentication code not received via SMS (Batch #4)','Team members on Vodafone network in Mumbai report OTP SMS messages are not arriving.','solved','normal',5,7,0,NULL,'2026-11-20T13:52:01.165217+00:00','2026-11-19T15:52:01.165217+00:00','2026-11-19T13:52:01.165217+00:00','2026-11-19T15:52:01.165217+00:00');
INSERT INTO tickets VALUES(66,'Invoice for October missing tax deduction breakdown (Batch #4)','The latest consolidated invoice does not show the GST breakdown required by our accounting department.','solved','normal',6,2,0,NULL,'2026-11-20T15:04:01.165217+00:00','2026-11-19T17:04:01.165217+00:00','2026-11-19T15:04:01.165217+00:00','2026-11-19T17:04:01.165217+00:00');
INSERT INTO tickets VALUES(67,'Feature Request: Add dark mode toggle in portal (Batch #4)','Would greatly appreciate a system-level dark theme for our agents working night shifts.','solved','normal',7,9,0,NULL,'2026-11-20T16:16:01.165217+00:00','2026-11-19T18:16:01.165217+00:00','2026-11-19T16:16:01.165217+00:00','2026-11-19T18:16:01.165217+00:00');
INSERT INTO tickets VALUES(68,'API rate limit reached unexpectedly on /tickets endpoint (Batch #4)','Our integration script received 429 Too Many Requests despite staying within the 100 req/min limit.','solved','normal',8,4,0,NULL,'2026-11-20T17:28:01.165217+00:00','2026-11-19T19:28:01.165217+00:00','2026-11-19T17:28:01.165217+00:00','2026-11-19T19:28:01.165217+00:00');
INSERT INTO tickets VALUES(69,'Dashboard widget charts failing to load on Safari (Batch #4)','Analytics graphs render blank in Safari 17.2, though they display properly in Chrome and Firefox.','solved','normal',9,2,0,NULL,'2026-11-20T18:40:01.165217+00:00','2026-11-19T20:40:01.165217+00:00','2026-11-19T18:40:01.165217+00:00','2026-11-19T20:40:01.165217+00:00');
INSERT INTO tickets VALUES(70,'Unable to invite new team members with Admin role (Batch #4)','When sending invite email to new supervisor, the role dropdown resets to Agent.','solved','normal',10,7,0,NULL,'2026-11-20T19:52:01.165217+00:00','2026-11-19T21:52:01.165217+00:00','2026-11-19T19:52:01.165217+00:00','2026-11-19T21:52:01.165217+00:00');
INSERT INTO tickets VALUES(71,'SSL certificate warning on custom domain setup (Batch #4)','Visiting support.acme.com shows NET::ERR_CERT_COMMON_NAME_INVALID error.','solved','normal',1,2,0,NULL,'2026-11-20T21:04:01.165217+00:00','2026-11-19T23:04:01.165217+00:00','2026-11-19T21:04:01.165217+00:00','2026-11-19T23:04:01.165217+00:00');
INSERT INTO tickets VALUES(72,'Password reset email link expired immediately (Batch #4)','The link sent to our director expired within 2 minutes instead of the documented 24 hours.','solved','normal',2,7,0,NULL,'2026-11-20T22:16:01.165217+00:00','2026-11-20T00:16:01.165217+00:00','2026-11-19T22:16:01.165217+00:00','2026-11-20T00:16:01.165217+00:00');
INSERT INTO tickets VALUES(73,'Slow query response on ticket search with multiple tags (Batch #4)','Full-text search queries take over 4 seconds when searching with 3 or more tags.','solved','normal',3,4,0,NULL,'2026-11-20T23:28:01.165217+00:00','2026-11-20T01:28:01.165217+00:00','2026-11-19T23:28:01.165217+00:00','2026-11-20T01:28:01.165217+00:00');
INSERT INTO tickets VALUES(74,'Need SOC2 Type II compliance report for annual audit (Batch #4)','Our security team requires your latest SOC2 compliance summary for our vendor review.','solved','normal',4,9,0,NULL,'2026-11-21T00:40:01.165217+00:00','2026-11-20T02:40:01.165217+00:00','2026-11-20T00:40:01.165217+00:00','2026-11-20T02:40:01.165217+00:00');
INSERT INTO tickets VALUES(75,'CSV import failing with invalid character encoding (Batch #4)','Importing user list fails on row 142 due to non-ASCII accented characters in customer names.','solved','normal',5,7,0,NULL,'2026-11-21T01:52:01.165217+00:00','2026-11-20T03:52:01.165217+00:00','2026-11-20T01:52:01.165217+00:00','2026-11-20T03:52:01.165217+00:00');
INSERT INTO tickets VALUES(76,'Email notification not sent when ticket is assigned (Batch #4)','Agent assignment notifications stopped firing around 09:00 UTC this morning.','solved','normal',6,2,0,NULL,'2026-11-21T03:04:01.165217+00:00','2026-11-20T05:04:01.165217+00:00','2026-11-20T03:04:01.165217+00:00','2026-11-20T05:04:01.165217+00:00');
INSERT INTO tickets VALUES(77,'Mobile responsive view breaks on conversation thread (Batch #4)','Long code snippets in message threads overflow the viewport on iOS Safari.','solved','normal',7,9,0,NULL,'2026-11-21T04:16:01.165217+00:00','2026-11-20T06:16:01.165217+00:00','2026-11-20T04:16:01.165217+00:00','2026-11-20T06:16:01.165217+00:00');
INSERT INTO tickets VALUES(78,'Session timeout logging agents out every 10 minutes (Batch #4)','Staff are repeatedly prompted to log in while drafting responses to customers.','solved','normal',8,4,0,NULL,'2026-11-21T05:28:01.165217+00:00','2026-11-20T07:28:01.165217+00:00','2026-11-20T05:28:01.165217+00:00','2026-11-20T07:28:01.165217+00:00');
INSERT INTO tickets VALUES(79,'Cannot download PDF attachments larger than 10MB (Batch #4)','Attempting to download architecture diagrams returns HTTP 413 Payload Too Large.','solved','normal',9,2,0,NULL,'2026-11-21T06:40:01.165217+00:00','2026-11-20T08:40:01.165217+00:00','2026-11-20T06:40:01.165217+00:00','2026-11-20T08:40:01.165217+00:00');
INSERT INTO tickets VALUES(80,'Requesting sandbox environment reset for QA testing (Batch #4)','Please flush the staging database and seed fresh demo tickets for our upcoming demo.','solved','normal',10,7,0,NULL,'2026-11-21T07:52:01.165217+00:00','2026-11-20T09:52:01.165217+00:00','2026-11-20T07:52:01.165217+00:00','2026-11-20T09:52:01.165217+00:00');
INSERT INTO tickets VALUES(81,'SSO login failure with Okta integration (Batch #5)','Users in EU region cannot authenticate via SAML 2.0; receiving ''Invalid SAML response'' error on callback.','closed','low',1,2,0,NULL,'2026-11-22T09:04:01.165217+00:00','2026-11-20T11:04:01.165217+00:00','2026-11-20T09:04:01.165217+00:00','2026-11-20T11:04:01.165217+00:00');
INSERT INTO tickets VALUES(82,'Payment gateway returned error 502 on renewal (Batch #5)','Annual subscription failed during automated Stripe charge. Need invoice reissued.','closed','low',2,7,0,NULL,'2026-11-22T10:16:01.165217+00:00','2026-11-20T12:16:01.165217+00:00','2026-11-20T10:16:01.165217+00:00','2026-11-20T12:16:01.165217+00:00');
INSERT INTO tickets VALUES(83,'Need bulk export of customer contact records (Batch #5)','Please provide a complete CSV dump of our company contacts created before Q3.','closed','low',3,4,0,NULL,'2026-11-22T11:28:01.165217+00:00','2026-11-20T13:28:01.165217+00:00','2026-11-20T11:28:01.165217+00:00','2026-11-20T13:28:01.165217+00:00');
INSERT INTO tickets VALUES(84,'Webhook delivery latency exceeding 5 seconds (Batch #5)','Event callbacks for ticket.updated are delayed by up to 10 minutes during peak hours.','closed','low',4,9,0,NULL,'2026-11-22T12:40:01.165217+00:00','2026-11-20T14:40:01.165217+00:00','2026-11-20T12:40:01.165217+00:00','2026-11-20T14:40:01.165217+00:00');
INSERT INTO tickets VALUES(85,'Two-factor authentication code not received via SMS (Batch #5)','Team members on Vodafone network in Mumbai report OTP SMS messages are not arriving.','closed','low',5,7,0,NULL,'2026-11-22T13:52:01.165217+00:00','2026-11-20T15:52:01.165217+00:00','2026-11-20T13:52:01.165217+00:00','2026-11-20T15:52:01.165217+00:00');
INSERT INTO tickets VALUES(86,'Invoice for October missing tax deduction breakdown (Batch #5)','The latest consolidated invoice does not show the GST breakdown required by our accounting department.','closed','low',6,2,0,NULL,'2026-11-22T15:04:01.165217+00:00','2026-11-20T17:04:01.165217+00:00','2026-11-20T15:04:01.165217+00:00','2026-11-20T17:04:01.165217+00:00');
INSERT INTO tickets VALUES(87,'Feature Request: Add dark mode toggle in portal (Batch #5)','Would greatly appreciate a system-level dark theme for our agents working night shifts.','closed','low',7,9,0,NULL,'2026-11-22T16:16:01.165217+00:00','2026-11-20T18:16:01.165217+00:00','2026-11-20T16:16:01.165217+00:00','2026-11-20T18:16:01.165217+00:00');
INSERT INTO tickets VALUES(88,'API rate limit reached unexpectedly on /tickets endpoint (Batch #5)','Our integration script received 429 Too Many Requests despite staying within the 100 req/min limit.','closed','low',8,4,0,NULL,'2026-11-22T17:28:01.165217+00:00','2026-11-20T19:28:01.165217+00:00','2026-11-20T17:28:01.165217+00:00','2026-11-20T19:28:01.165217+00:00');
INSERT INTO tickets VALUES(89,'Dashboard widget charts failing to load on Safari (Batch #5)','Analytics graphs render blank in Safari 17.2, though they display properly in Chrome and Firefox.','closed','low',9,2,0,NULL,'2026-11-22T18:40:01.165217+00:00','2026-11-20T20:40:01.165217+00:00','2026-11-20T18:40:01.165217+00:00','2026-11-20T20:40:01.165217+00:00');
INSERT INTO tickets VALUES(90,'Unable to invite new team members with Admin role (Batch #5)','When sending invite email to new supervisor, the role dropdown resets to Agent.','closed','low',10,7,0,NULL,'2026-11-22T19:52:01.165217+00:00','2026-11-20T21:52:01.165217+00:00','2026-11-20T19:52:01.165217+00:00','2026-11-20T21:52:01.165217+00:00');
INSERT INTO tickets VALUES(91,'SSL certificate warning on custom domain setup (Batch #5)','Visiting support.acme.com shows NET::ERR_CERT_COMMON_NAME_INVALID error.','open','normal',1,1,1,NULL,'2026-11-21T21:04:01.165217+00:00',NULL,'2026-11-20T21:04:01.165217+00:00','2026-11-20T23:04:01.165217+00:00');
INSERT INTO tickets VALUES(92,'Password reset email link expired immediately (Batch #5)','The link sent to our director expired within 2 minutes instead of the documented 24 hours.','open','normal',2,1,1,NULL,'2026-11-21T22:16:01.165217+00:00',NULL,'2026-11-20T22:16:01.165217+00:00','2026-11-21T00:16:01.165217+00:00');
INSERT INTO tickets VALUES(93,'Slow query response on ticket search with multiple tags (Batch #5)','Full-text search queries take over 4 seconds when searching with 3 or more tags.','open','normal',3,1,1,NULL,'2026-11-21T23:28:01.165217+00:00',NULL,'2026-11-20T23:28:01.165217+00:00','2026-11-21T01:28:01.165217+00:00');
INSERT INTO tickets VALUES(94,'Need SOC2 Type II compliance report for annual audit (Batch #5)','Our security team requires your latest SOC2 compliance summary for our vendor review.','open','normal',4,1,1,NULL,'2026-11-22T00:40:01.165217+00:00',NULL,'2026-11-21T00:40:01.165217+00:00','2026-11-21T02:40:01.165217+00:00');
INSERT INTO tickets VALUES(95,'CSV import failing with invalid character encoding (Batch #5)','Importing user list fails on row 142 due to non-ASCII accented characters in customer names.','open','normal',5,1,1,NULL,'2026-11-22T01:52:01.165217+00:00',NULL,'2026-11-21T01:52:01.165217+00:00','2026-11-21T03:52:01.165217+00:00');
INSERT INTO tickets VALUES(96,'Email notification not sent when ticket is assigned (Batch #5)','Agent assignment notifications stopped firing around 09:00 UTC this morning.','pending','normal',6,1,1,NULL,'2026-11-22T03:04:01.165217+00:00',NULL,'2026-11-21T03:04:01.165217+00:00','2026-11-21T05:04:01.165217+00:00');
INSERT INTO tickets VALUES(97,'Mobile responsive view breaks on conversation thread (Batch #5)','Long code snippets in message threads overflow the viewport on iOS Safari.','pending','normal',7,1,1,NULL,'2026-11-22T04:16:01.165217+00:00',NULL,'2026-11-21T04:16:01.165217+00:00','2026-11-21T06:16:01.165217+00:00');
INSERT INTO tickets VALUES(98,'Session timeout logging agents out every 10 minutes (Batch #5)','Staff are repeatedly prompted to log in while drafting responses to customers.','pending','normal',8,1,1,NULL,'2026-11-22T05:28:01.165217+00:00',NULL,'2026-11-21T05:28:01.165217+00:00','2026-11-21T07:16:01.165217+00:00');
INSERT INTO tickets VALUES(99,'Cannot download PDF attachments larger than 10MB (Batch #5)','Attempting to download architecture diagrams returns HTTP 413 Payload Too Large.','pending','normal',9,1,1,NULL,'2026-11-22T06:40:01.165217+00:00',NULL,'2026-11-21T06:40:01.165217+00:00','2026-11-21T07:52:01.165217+00:00');
INSERT INTO tickets VALUES(100,'Requesting sandbox environment reset for QA testing (Batch #5)','Please flush the staging database and seed fresh demo tickets for our upcoming demo.','pending','normal',10,1,1,NULL,'2026-11-22T07:52:01.165217+00:00',NULL,'2026-11-21T07:52:01.165217+00:00','2026-11-21T08:28:01.165217+00:00');
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    sender_type TEXT NOT NULL CHECK(sender_type IN ('client', 'agent', 'admin', 'user')),
    text TEXT NOT NULL,
    visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'internal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
);
INSERT INTO messages VALUES(1,1,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:58:01.165217+00:00');
INSERT INTO messages VALUES(2,2,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:40:15.565217+00:00');
INSERT INTO messages VALUES(3,3,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:22:29.965217+00:00');
INSERT INTO messages VALUES(4,4,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:52:44.365217+00:00');
INSERT INTO messages VALUES(5,5,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:34:58.765217+00:00');
INSERT INTO messages VALUES(6,6,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:17:13.165217+00:00');
INSERT INTO messages VALUES(7,7,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:47:27.565217+00:00');
INSERT INTO messages VALUES(8,8,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:29:41.965217+00:00');
INSERT INTO messages VALUES(9,9,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:11:56.365217+00:00');
INSERT INTO messages VALUES(10,10,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:42:10.765217+00:00');
INSERT INTO messages VALUES(11,11,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:24:25.165217+00:00');
INSERT INTO messages VALUES(12,12,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:37:01.165217+00:00');
INSERT INTO messages VALUES(13,13,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:15:32.365217+00:00');
INSERT INTO messages VALUES(14,14,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:04:29.965217+00:00');
INSERT INTO messages VALUES(15,15,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:05:27.565217+00:00');
INSERT INTO messages VALUES(16,16,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:54:25.165217+00:00');
INSERT INTO messages VALUES(17,17,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T05:43:22.765217+00:00');
INSERT INTO messages VALUES(18,18,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:44:20.365217+00:00');
INSERT INTO messages VALUES(19,19,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:33:17.965217+00:00');
INSERT INTO messages VALUES(20,20,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:34:15.565217+00:00');
INSERT INTO messages VALUES(21,21,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:23:13.165217+00:00');
INSERT INTO messages VALUES(22,22,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:12:10.765217+00:00');
INSERT INTO messages VALUES(23,23,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:13:08.365217+00:00');
INSERT INTO messages VALUES(24,24,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T04:25:01.165217+00:00');
INSERT INTO messages VALUES(25,25,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T05:51:03.565217+00:00');
INSERT INTO messages VALUES(26,26,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:52:01.165217+00:00');
INSERT INTO messages VALUES(27,27,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:40:58.765217+00:00');
INSERT INTO messages VALUES(28,28,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T05:29:56.365217+00:00');
INSERT INTO messages VALUES(29,29,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:30:53.965217+00:00');
INSERT INTO messages VALUES(30,30,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:19:51.565217+00:00');
INSERT INTO messages VALUES(31,31,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T08:20:49.165217+00:00');
INSERT INTO messages VALUES(32,32,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:09:46.765217+00:00');
INSERT INTO messages VALUES(33,33,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T05:58:44.365217+00:00');
INSERT INTO messages VALUES(34,34,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:59:41.965217+00:00');
INSERT INTO messages VALUES(35,35,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T19:31:51.565217+00:00');
INSERT INTO messages VALUES(36,36,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T08:43:01.165217+00:00');
INSERT INTO messages VALUES(37,36,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T09:28:01.165217+00:00');
INSERT INTO messages VALUES(38,36,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T09:28:01.165217+00:00');
INSERT INTO messages VALUES(39,37,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T00:31:22.765217+00:00');
INSERT INTO messages VALUES(40,37,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T01:16:22.765217+00:00');
INSERT INTO messages VALUES(41,37,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T01:16:22.765217+00:00');
INSERT INTO messages VALUES(42,38,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T17:25:08.365217+00:00');
INSERT INTO messages VALUES(43,38,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T18:10:08.365217+00:00');
INSERT INTO messages VALUES(44,38,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T18:10:08.365217+00:00');
INSERT INTO messages VALUES(45,39,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T05:30:53.965217+00:00');
INSERT INTO messages VALUES(46,39,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T06:15:53.965217+00:00');
INSERT INTO messages VALUES(47,39,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T06:15:53.965217+00:00');
INSERT INTO messages VALUES(48,40,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T22:24:39.565217+00:00');
INSERT INTO messages VALUES(49,40,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T23:09:39.565217+00:00');
INSERT INTO messages VALUES(50,40,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T23:09:39.565217+00:00');
INSERT INTO messages VALUES(51,41,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T15:18:25.165217+00:00');
INSERT INTO messages VALUES(52,42,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T03:24:10.765217+00:00');
INSERT INTO messages VALUES(53,42,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T04:09:10.765217+00:00');
INSERT INTO messages VALUES(54,42,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T04:09:10.765217+00:00');
INSERT INTO messages VALUES(55,43,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T20:17:56.365217+00:00');
INSERT INTO messages VALUES(56,43,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T21:02:56.365217+00:00');
INSERT INTO messages VALUES(57,43,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T21:02:56.365217+00:00');
INSERT INTO messages VALUES(58,44,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T13:11:41.965217+00:00');
INSERT INTO messages VALUES(59,44,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T13:56:41.965217+00:00');
INSERT INTO messages VALUES(60,44,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T13:56:41.965217+00:00');
INSERT INTO messages VALUES(61,45,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T01:17:27.565217+00:00');
INSERT INTO messages VALUES(62,45,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T02:02:27.565217+00:00');
INSERT INTO messages VALUES(63,45,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T02:02:27.565217+00:00');
INSERT INTO messages VALUES(64,46,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T18:11:13.165217+00:00');
INSERT INTO messages VALUES(65,46,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T18:56:13.165217+00:00');
INSERT INTO messages VALUES(66,46,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T18:56:13.165217+00:00');
INSERT INTO messages VALUES(67,47,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:16:58.765217+00:00');
INSERT INTO messages VALUES(68,47,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T07:01:58.765217+00:00');
INSERT INTO messages VALUES(69,47,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T07:01:58.765217+00:00');
INSERT INTO messages VALUES(70,48,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T08:31:01.165217+00:00');
INSERT INTO messages VALUES(71,48,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T09:16:01.165217+00:00');
INSERT INTO messages VALUES(72,48,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T09:16:01.165217+00:00');
INSERT INTO messages VALUES(73,49,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T16:04:29.965217+00:00');
INSERT INTO messages VALUES(74,49,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T16:49:29.965217+00:00');
INSERT INTO messages VALUES(75,49,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T16:49:29.965217+00:00');
INSERT INTO messages VALUES(76,50,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T04:10:15.565217+00:00');
INSERT INTO messages VALUES(77,50,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T04:55:15.565217+00:00');
INSERT INTO messages VALUES(78,50,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T04:55:15.565217+00:00');
INSERT INTO messages VALUES(79,51,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T21:04:01.165217+00:00');
INSERT INTO messages VALUES(80,52,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T13:57:46.765217+00:00');
INSERT INTO messages VALUES(81,52,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T14:42:46.765217+00:00');
INSERT INTO messages VALUES(82,52,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T14:42:46.765217+00:00');
INSERT INTO messages VALUES(83,53,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T02:03:32.365217+00:00');
INSERT INTO messages VALUES(84,53,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T02:48:32.365217+00:00');
INSERT INTO messages VALUES(85,53,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T02:48:32.365217+00:00');
INSERT INTO messages VALUES(86,54,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T18:57:17.965217+00:00');
INSERT INTO messages VALUES(87,54,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T19:42:17.965217+00:00');
INSERT INTO messages VALUES(88,54,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T19:42:17.965217+00:00');
INSERT INTO messages VALUES(89,55,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T11:51:03.565217+00:00');
INSERT INTO messages VALUES(90,55,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T12:36:03.565217+00:00');
INSERT INTO messages VALUES(91,55,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T12:36:03.565217+00:00');
INSERT INTO messages VALUES(92,56,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T23:56:49.165217+00:00');
INSERT INTO messages VALUES(93,56,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T00:41:49.165217+00:00');
INSERT INTO messages VALUES(94,56,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T00:41:49.165217+00:00');
INSERT INTO messages VALUES(95,57,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T16:50:34.765217+00:00');
INSERT INTO messages VALUES(96,57,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T17:35:34.765217+00:00');
INSERT INTO messages VALUES(97,57,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T17:35:34.765217+00:00');
INSERT INTO messages VALUES(98,58,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T04:56:20.365217+00:00');
INSERT INTO messages VALUES(99,58,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T05:41:20.365217+00:00');
INSERT INTO messages VALUES(100,58,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T05:41:20.365217+00:00');
INSERT INTO messages VALUES(101,59,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T21:50:05.965217+00:00');
INSERT INTO messages VALUES(102,59,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T22:35:05.965217+00:00');
INSERT INTO messages VALUES(103,59,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T22:35:05.965217+00:00');
INSERT INTO messages VALUES(104,60,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T08:49:01.165217+00:00');
INSERT INTO messages VALUES(105,60,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T09:34:01.165217+00:00');
INSERT INTO messages VALUES(106,60,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T09:34:01.165217+00:00');
INSERT INTO messages VALUES(107,61,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T09:04:01.165217+00:00');
INSERT INTO messages VALUES(108,61,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T09:49:01.165217+00:00');
INSERT INTO messages VALUES(109,61,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T09:49:01.165217+00:00');
INSERT INTO messages VALUES(110,62,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T10:16:01.165217+00:00');
INSERT INTO messages VALUES(111,62,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T11:01:01.165217+00:00');
INSERT INTO messages VALUES(112,62,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T11:01:01.165217+00:00');
INSERT INTO messages VALUES(113,63,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T11:28:01.165217+00:00');
INSERT INTO messages VALUES(114,63,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T12:13:01.165217+00:00');
INSERT INTO messages VALUES(115,63,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T12:13:01.165217+00:00');
INSERT INTO messages VALUES(116,64,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T12:40:01.165217+00:00');
INSERT INTO messages VALUES(117,64,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T13:25:01.165217+00:00');
INSERT INTO messages VALUES(118,64,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T13:25:01.165217+00:00');
INSERT INTO messages VALUES(119,65,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T13:52:01.165217+00:00');
INSERT INTO messages VALUES(120,65,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T14:37:01.165217+00:00');
INSERT INTO messages VALUES(121,65,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T14:37:01.165217+00:00');
INSERT INTO messages VALUES(122,66,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T15:04:01.165217+00:00');
INSERT INTO messages VALUES(123,66,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T15:49:01.165217+00:00');
INSERT INTO messages VALUES(124,66,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T15:49:01.165217+00:00');
INSERT INTO messages VALUES(125,67,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T16:16:01.165217+00:00');
INSERT INTO messages VALUES(126,67,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T17:01:01.165217+00:00');
INSERT INTO messages VALUES(127,67,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T17:01:01.165217+00:00');
INSERT INTO messages VALUES(128,68,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T17:28:01.165217+00:00');
INSERT INTO messages VALUES(129,68,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T18:13:01.165217+00:00');
INSERT INTO messages VALUES(130,68,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T18:13:01.165217+00:00');
INSERT INTO messages VALUES(131,69,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T18:40:01.165217+00:00');
INSERT INTO messages VALUES(132,69,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T19:25:01.165217+00:00');
INSERT INTO messages VALUES(133,69,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T19:25:01.165217+00:00');
INSERT INTO messages VALUES(134,70,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T19:52:01.165217+00:00');
INSERT INTO messages VALUES(135,70,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T20:37:01.165217+00:00');
INSERT INTO messages VALUES(136,70,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T20:37:01.165217+00:00');
INSERT INTO messages VALUES(137,71,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T21:04:01.165217+00:00');
INSERT INTO messages VALUES(138,71,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T21:49:01.165217+00:00');
INSERT INTO messages VALUES(139,71,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T21:49:01.165217+00:00');
INSERT INTO messages VALUES(140,72,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T22:16:01.165217+00:00');
INSERT INTO messages VALUES(141,72,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-19T23:01:01.165217+00:00');
INSERT INTO messages VALUES(142,72,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-19T23:01:01.165217+00:00');
INSERT INTO messages VALUES(143,73,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-19T23:28:01.165217+00:00');
INSERT INTO messages VALUES(144,73,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T00:13:01.165217+00:00');
INSERT INTO messages VALUES(145,73,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T00:13:01.165217+00:00');
INSERT INTO messages VALUES(146,74,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T00:40:01.165217+00:00');
INSERT INTO messages VALUES(147,74,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T01:25:01.165217+00:00');
INSERT INTO messages VALUES(148,74,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T01:25:01.165217+00:00');
INSERT INTO messages VALUES(149,75,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T01:52:01.165217+00:00');
INSERT INTO messages VALUES(150,75,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T02:37:01.165217+00:00');
INSERT INTO messages VALUES(151,75,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T02:37:01.165217+00:00');
INSERT INTO messages VALUES(152,76,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T03:04:01.165217+00:00');
INSERT INTO messages VALUES(153,76,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T03:49:01.165217+00:00');
INSERT INTO messages VALUES(154,76,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T03:49:01.165217+00:00');
INSERT INTO messages VALUES(155,77,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T04:16:01.165217+00:00');
INSERT INTO messages VALUES(156,77,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T05:01:01.165217+00:00');
INSERT INTO messages VALUES(157,77,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T05:01:01.165217+00:00');
INSERT INTO messages VALUES(158,78,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T05:28:01.165217+00:00');
INSERT INTO messages VALUES(159,78,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T06:13:01.165217+00:00');
INSERT INTO messages VALUES(160,78,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T06:13:01.165217+00:00');
INSERT INTO messages VALUES(161,79,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T06:40:01.165217+00:00');
INSERT INTO messages VALUES(162,79,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T07:25:01.165217+00:00');
INSERT INTO messages VALUES(163,79,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T07:25:01.165217+00:00');
INSERT INTO messages VALUES(164,80,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T07:52:01.165217+00:00');
INSERT INTO messages VALUES(165,80,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T08:37:01.165217+00:00');
INSERT INTO messages VALUES(166,80,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T08:37:01.165217+00:00');
INSERT INTO messages VALUES(167,81,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T09:04:01.165217+00:00');
INSERT INTO messages VALUES(168,81,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T09:49:01.165217+00:00');
INSERT INTO messages VALUES(169,81,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T09:49:01.165217+00:00');
INSERT INTO messages VALUES(170,82,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T10:16:01.165217+00:00');
INSERT INTO messages VALUES(171,82,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T11:01:01.165217+00:00');
INSERT INTO messages VALUES(172,82,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T11:01:01.165217+00:00');
INSERT INTO messages VALUES(173,83,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T11:28:01.165217+00:00');
INSERT INTO messages VALUES(174,83,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T12:13:01.165217+00:00');
INSERT INTO messages VALUES(175,83,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T12:13:01.165217+00:00');
INSERT INTO messages VALUES(176,84,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T12:40:01.165217+00:00');
INSERT INTO messages VALUES(177,84,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T13:25:01.165217+00:00');
INSERT INTO messages VALUES(178,84,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T13:25:01.165217+00:00');
INSERT INTO messages VALUES(179,85,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T13:52:01.165217+00:00');
INSERT INTO messages VALUES(180,85,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T14:37:01.165217+00:00');
INSERT INTO messages VALUES(181,85,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T14:37:01.165217+00:00');
INSERT INTO messages VALUES(182,86,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T15:04:01.165217+00:00');
INSERT INTO messages VALUES(183,86,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T15:49:01.165217+00:00');
INSERT INTO messages VALUES(184,86,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T15:49:01.165217+00:00');
INSERT INTO messages VALUES(185,87,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T16:16:01.165217+00:00');
INSERT INTO messages VALUES(186,87,9,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T17:01:01.165217+00:00');
INSERT INTO messages VALUES(187,87,9,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T17:01:01.165217+00:00');
INSERT INTO messages VALUES(188,88,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T17:28:01.165217+00:00');
INSERT INTO messages VALUES(189,88,4,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T18:13:01.165217+00:00');
INSERT INTO messages VALUES(190,88,4,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T18:13:01.165217+00:00');
INSERT INTO messages VALUES(191,89,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T18:40:01.165217+00:00');
INSERT INTO messages VALUES(192,89,2,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T19:25:01.165217+00:00');
INSERT INTO messages VALUES(193,89,2,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T19:25:01.165217+00:00');
INSERT INTO messages VALUES(194,90,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T19:52:01.165217+00:00');
INSERT INTO messages VALUES(195,90,7,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-20T20:37:01.165217+00:00');
INSERT INTO messages VALUES(196,90,7,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-20T20:37:01.165217+00:00');
INSERT INTO messages VALUES(197,91,1,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T21:04:01.165217+00:00');
INSERT INTO messages VALUES(198,92,2,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T22:16:01.165217+00:00');
INSERT INTO messages VALUES(199,93,3,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-20T23:28:01.165217+00:00');
INSERT INTO messages VALUES(200,94,4,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T00:40:01.165217+00:00');
INSERT INTO messages VALUES(201,95,5,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T01:52:01.165217+00:00');
INSERT INTO messages VALUES(202,96,6,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T03:04:01.165217+00:00');
INSERT INTO messages VALUES(203,96,1,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T03:49:01.165217+00:00');
INSERT INTO messages VALUES(204,96,1,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T03:49:01.165217+00:00');
INSERT INTO messages VALUES(205,97,7,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T04:16:01.165217+00:00');
INSERT INTO messages VALUES(206,97,1,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T05:01:01.165217+00:00');
INSERT INTO messages VALUES(207,97,1,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T05:01:01.165217+00:00');
INSERT INTO messages VALUES(208,98,8,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T05:28:01.165217+00:00');
INSERT INTO messages VALUES(209,98,1,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T06:13:01.165217+00:00');
INSERT INTO messages VALUES(210,98,1,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T06:13:01.165217+00:00');
INSERT INTO messages VALUES(211,99,9,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T06:40:01.165217+00:00');
INSERT INTO messages VALUES(212,99,1,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T07:25:01.165217+00:00');
INSERT INTO messages VALUES(213,99,1,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T07:25:01.165217+00:00');
INSERT INTO messages VALUES(214,100,10,'client','Hello support team, please assist with this issue as soon as possible.','public','2026-11-21T07:52:01.165217+00:00');
INSERT INTO messages VALUES(215,100,1,'agent','We have investigated and applied the initial configuration patch. Please verify.','public','2026-11-21T08:37:01.165217+00:00');
INSERT INTO messages VALUES(216,100,1,'agent','Internal note: verified logs, database latency is back to normal.','internal','2026-11-21T08:37:01.165217+00:00');
CREATE TABLE worksheet (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    agent_id INTEGER,
    assigned_by INTEGER,
    reason TEXT, -- e.g. 'round_robin', 'manual_reassign', 'escalation'
    status TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by) REFERENCES agents(id) ON DELETE SET NULL
);
INSERT INTO worksheet VALUES(1,2,7,7,'round_robin','open','2026-11-21T08:40:15.565217+00:00');
INSERT INTO worksheet VALUES(2,3,4,4,'round_robin','open','2026-11-21T08:22:29.965217+00:00');
INSERT INTO worksheet VALUES(3,4,9,9,'round_robin','open','2026-11-21T08:52:44.365217+00:00');
INSERT INTO worksheet VALUES(4,5,7,7,'round_robin','open','2026-11-21T08:34:58.765217+00:00');
INSERT INTO worksheet VALUES(5,6,2,2,'round_robin','open','2026-11-21T08:17:13.165217+00:00');
INSERT INTO worksheet VALUES(6,7,9,9,'round_robin','open','2026-11-21T08:47:27.565217+00:00');
INSERT INTO worksheet VALUES(7,8,4,4,'round_robin','open','2026-11-21T08:29:41.965217+00:00');
INSERT INTO worksheet VALUES(8,9,2,2,'round_robin','open','2026-11-21T08:11:56.365217+00:00');
INSERT INTO worksheet VALUES(9,10,7,7,'round_robin','open','2026-11-21T08:42:10.765217+00:00');
INSERT INTO worksheet VALUES(10,12,7,7,'round_robin','open','2026-11-21T07:37:01.165217+00:00');
INSERT INTO worksheet VALUES(11,13,4,4,'round_robin','open','2026-11-21T07:15:32.365217+00:00');
INSERT INTO worksheet VALUES(12,14,9,9,'round_robin','open','2026-11-21T06:04:29.965217+00:00');
INSERT INTO worksheet VALUES(13,15,7,7,'round_robin','open','2026-11-21T08:05:27.565217+00:00');
INSERT INTO worksheet VALUES(14,16,2,2,'round_robin','open','2026-11-21T06:54:25.165217+00:00');
INSERT INTO worksheet VALUES(15,17,9,9,'round_robin','open','2026-11-21T05:43:22.765217+00:00');
INSERT INTO worksheet VALUES(16,18,4,4,'round_robin','open','2026-11-21T07:44:20.365217+00:00');
INSERT INTO worksheet VALUES(17,19,2,2,'round_robin','open','2026-11-21T06:33:17.965217+00:00');
INSERT INTO worksheet VALUES(18,20,7,7,'round_robin','open','2026-11-21T08:34:15.565217+00:00');
INSERT INTO worksheet VALUES(19,22,7,7,'round_robin','open','2026-11-21T06:12:10.765217+00:00');
INSERT INTO worksheet VALUES(20,23,4,4,'round_robin','open','2026-11-21T08:13:08.365217+00:00');
INSERT INTO worksheet VALUES(21,24,9,9,'round_robin','open','2026-11-21T04:25:01.165217+00:00');
INSERT INTO worksheet VALUES(22,25,7,7,'round_robin','open','2026-11-21T05:51:03.565217+00:00');
INSERT INTO worksheet VALUES(23,26,2,2,'round_robin','open','2026-11-21T07:52:01.165217+00:00');
INSERT INTO worksheet VALUES(24,27,9,9,'round_robin','open','2026-11-21T06:40:58.765217+00:00');
INSERT INTO worksheet VALUES(25,28,4,4,'round_robin','open','2026-11-21T05:29:56.365217+00:00');
INSERT INTO worksheet VALUES(26,29,2,2,'round_robin','open','2026-11-21T07:30:53.965217+00:00');
INSERT INTO worksheet VALUES(27,30,7,7,'round_robin','open','2026-11-21T06:19:51.565217+00:00');
INSERT INTO worksheet VALUES(28,32,7,7,'round_robin','open','2026-11-21T07:09:46.765217+00:00');
INSERT INTO worksheet VALUES(29,33,4,4,'round_robin','open','2026-11-21T05:58:44.365217+00:00');
INSERT INTO worksheet VALUES(30,34,9,9,'round_robin','open','2026-11-21T07:59:41.965217+00:00');
INSERT INTO worksheet VALUES(31,35,7,7,'round_robin','open','2026-11-20T19:31:51.565217+00:00');
INSERT INTO worksheet VALUES(32,36,2,2,'round_robin','pending','2026-11-20T08:43:01.165217+00:00');
INSERT INTO worksheet VALUES(33,37,9,9,'round_robin','pending','2026-11-21T00:31:22.765217+00:00');
INSERT INTO worksheet VALUES(34,38,4,4,'round_robin','pending','2026-11-20T17:25:08.365217+00:00');
INSERT INTO worksheet VALUES(35,39,2,2,'round_robin','pending','2026-11-21T05:30:53.965217+00:00');
INSERT INTO worksheet VALUES(36,40,7,7,'round_robin','pending','2026-11-20T22:24:39.565217+00:00');
INSERT INTO worksheet VALUES(37,42,7,7,'round_robin','pending','2026-11-21T03:24:10.765217+00:00');
INSERT INTO worksheet VALUES(38,43,4,4,'round_robin','pending','2026-11-20T20:17:56.365217+00:00');
INSERT INTO worksheet VALUES(39,44,9,9,'round_robin','pending','2026-11-20T13:11:41.965217+00:00');
INSERT INTO worksheet VALUES(40,45,7,7,'round_robin','pending','2026-11-21T01:17:27.565217+00:00');
INSERT INTO worksheet VALUES(41,46,2,2,'round_robin','pending','2026-11-20T18:11:13.165217+00:00');
INSERT INTO worksheet VALUES(42,47,9,9,'round_robin','pending','2026-11-21T06:16:58.765217+00:00');
INSERT INTO worksheet VALUES(43,48,4,4,'round_robin','pending','2026-11-20T08:31:01.165217+00:00');
INSERT INTO worksheet VALUES(44,49,2,2,'round_robin','pending','2026-11-20T16:04:29.965217+00:00');
INSERT INTO worksheet VALUES(45,50,7,7,'round_robin','pending','2026-11-21T04:10:15.565217+00:00');
INSERT INTO worksheet VALUES(46,52,7,7,'round_robin','pending','2026-11-20T13:57:46.765217+00:00');
INSERT INTO worksheet VALUES(47,53,4,4,'round_robin','pending','2026-11-21T02:03:32.365217+00:00');
INSERT INTO worksheet VALUES(48,54,9,9,'round_robin','pending','2026-11-20T18:57:17.965217+00:00');
INSERT INTO worksheet VALUES(49,55,7,7,'round_robin','pending','2026-11-20T11:51:03.565217+00:00');
INSERT INTO worksheet VALUES(50,56,2,2,'round_robin','pending','2026-11-20T23:56:49.165217+00:00');
INSERT INTO worksheet VALUES(51,57,9,9,'round_robin','pending','2026-11-20T16:50:34.765217+00:00');
INSERT INTO worksheet VALUES(52,58,4,4,'round_robin','pending','2026-11-21T04:56:20.365217+00:00');
INSERT INTO worksheet VALUES(53,59,2,2,'round_robin','pending','2026-11-20T21:50:05.965217+00:00');
INSERT INTO worksheet VALUES(54,60,7,7,'round_robin','pending','2026-11-20T08:49:01.165217+00:00');
INSERT INTO worksheet VALUES(55,61,2,2,'round_robin','solved','2026-11-19T09:04:01.165217+00:00');
INSERT INTO worksheet VALUES(56,62,7,7,'round_robin','solved','2026-11-19T10:16:01.165217+00:00');
INSERT INTO worksheet VALUES(57,63,4,4,'round_robin','solved','2026-11-19T11:28:01.165217+00:00');
INSERT INTO worksheet VALUES(58,64,9,9,'round_robin','solved','2026-11-19T12:40:01.165217+00:00');
INSERT INTO worksheet VALUES(59,65,7,7,'round_robin','solved','2026-11-19T13:52:01.165217+00:00');
INSERT INTO worksheet VALUES(60,66,2,2,'round_robin','solved','2026-11-19T15:04:01.165217+00:00');
INSERT INTO worksheet VALUES(61,67,9,9,'round_robin','solved','2026-11-19T16:16:01.165217+00:00');
INSERT INTO worksheet VALUES(62,68,4,4,'round_robin','solved','2026-11-19T17:28:01.165217+00:00');
INSERT INTO worksheet VALUES(63,69,2,2,'round_robin','solved','2026-11-19T18:40:01.165217+00:00');
INSERT INTO worksheet VALUES(64,70,7,7,'round_robin','solved','2026-11-19T19:52:01.165217+00:00');
INSERT INTO worksheet VALUES(65,71,2,2,'round_robin','solved','2026-11-19T21:04:01.165217+00:00');
INSERT INTO worksheet VALUES(66,72,7,7,'round_robin','solved','2026-11-19T22:16:01.165217+00:00');
INSERT INTO worksheet VALUES(67,73,4,4,'round_robin','solved','2026-11-19T23:28:01.165217+00:00');
INSERT INTO worksheet VALUES(68,74,9,9,'round_robin','solved','2026-11-20T00:40:01.165217+00:00');
INSERT INTO worksheet VALUES(69,75,7,7,'round_robin','solved','2026-11-20T01:52:01.165217+00:00');
INSERT INTO worksheet VALUES(70,76,2,2,'round_robin','solved','2026-11-20T03:04:01.165217+00:00');
INSERT INTO worksheet VALUES(71,77,9,9,'round_robin','solved','2026-11-20T04:16:01.165217+00:00');
INSERT INTO worksheet VALUES(72,78,4,4,'round_robin','solved','2026-11-20T05:28:01.165217+00:00');
INSERT INTO worksheet VALUES(73,79,2,2,'round_robin','solved','2026-11-20T06:40:01.165217+00:00');
INSERT INTO worksheet VALUES(74,80,7,7,'round_robin','solved','2026-11-20T07:52:01.165217+00:00');
INSERT INTO worksheet VALUES(75,81,2,2,'round_robin','closed','2026-11-20T09:04:01.165217+00:00');
INSERT INTO worksheet VALUES(76,82,7,7,'round_robin','closed','2026-11-20T10:16:01.165217+00:00');
INSERT INTO worksheet VALUES(77,83,4,4,'round_robin','closed','2026-11-20T11:28:01.165217+00:00');
INSERT INTO worksheet VALUES(78,84,9,9,'round_robin','closed','2026-11-20T12:40:01.165217+00:00');
INSERT INTO worksheet VALUES(79,85,7,7,'round_robin','closed','2026-11-20T13:52:01.165217+00:00');
INSERT INTO worksheet VALUES(80,86,2,2,'round_robin','closed','2026-11-20T15:04:01.165217+00:00');
INSERT INTO worksheet VALUES(81,87,9,9,'round_robin','closed','2026-11-20T16:16:01.165217+00:00');
INSERT INTO worksheet VALUES(82,88,4,4,'round_robin','closed','2026-11-20T17:28:01.165217+00:00');
INSERT INTO worksheet VALUES(83,89,2,2,'round_robin','closed','2026-11-20T18:40:01.165217+00:00');
INSERT INTO worksheet VALUES(84,90,7,7,'round_robin','closed','2026-11-20T19:52:01.165217+00:00');
INSERT INTO worksheet VALUES(85,91,1,NULL,'escalation','open','2026-11-20T21:04:01.165217+00:00');
INSERT INTO worksheet VALUES(86,92,1,NULL,'escalation','open','2026-11-20T22:16:01.165217+00:00');
INSERT INTO worksheet VALUES(87,93,1,NULL,'escalation','open','2026-11-20T23:28:01.165217+00:00');
INSERT INTO worksheet VALUES(88,94,1,NULL,'escalation','open','2026-11-21T00:40:01.165217+00:00');
INSERT INTO worksheet VALUES(89,95,1,NULL,'escalation','open','2026-11-21T01:52:01.165217+00:00');
INSERT INTO worksheet VALUES(90,96,1,NULL,'escalation','pending','2026-11-21T03:04:01.165217+00:00');
INSERT INTO worksheet VALUES(91,97,1,NULL,'escalation','pending','2026-11-21T04:16:01.165217+00:00');
INSERT INTO worksheet VALUES(92,98,1,NULL,'escalation','pending','2026-11-21T05:28:01.165217+00:00');
INSERT INTO worksheet VALUES(93,99,1,NULL,'escalation','pending','2026-11-21T06:40:01.165217+00:00');
INSERT INTO worksheet VALUES(94,100,1,NULL,'escalation','pending','2026-11-21T07:52:01.165217+00:00');
CREATE TABLE audit (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ticket_id INTEGER NOT NULL,
    actor_type TEXT NOT NULL, -- 'client', 'agent', 'admin'
    actor_id INTEGER NOT NULL,
    action TEXT NOT NULL,     -- 'created', 'assigned', 'status_change', 'message_added', 'escalated'
    old_value TEXT,
    new_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
);
INSERT INTO audit VALUES(1,1,'client',1,'created',NULL,'open','2026-11-21T08:58:01.165217+00:00');
INSERT INTO audit VALUES(2,2,'client',2,'created',NULL,'open','2026-11-21T08:40:15.565217+00:00');
INSERT INTO audit VALUES(3,2,'system',0,'assigned',NULL,'7','2026-11-21T08:40:15.565217+00:00');
INSERT INTO audit VALUES(4,3,'client',3,'created',NULL,'open','2026-11-21T08:22:29.965217+00:00');
INSERT INTO audit VALUES(5,3,'system',0,'assigned',NULL,'4','2026-11-21T08:22:29.965217+00:00');
INSERT INTO audit VALUES(6,4,'client',4,'created',NULL,'open','2026-11-21T08:52:44.365217+00:00');
INSERT INTO audit VALUES(7,4,'system',0,'assigned',NULL,'9','2026-11-21T08:52:44.365217+00:00');
INSERT INTO audit VALUES(8,5,'client',5,'created',NULL,'open','2026-11-21T08:34:58.765217+00:00');
INSERT INTO audit VALUES(9,5,'system',0,'assigned',NULL,'7','2026-11-21T08:34:58.765217+00:00');
INSERT INTO audit VALUES(10,6,'client',6,'created',NULL,'open','2026-11-21T08:17:13.165217+00:00');
INSERT INTO audit VALUES(11,6,'system',0,'assigned',NULL,'2','2026-11-21T08:17:13.165217+00:00');
INSERT INTO audit VALUES(12,7,'client',7,'created',NULL,'open','2026-11-21T08:47:27.565217+00:00');
INSERT INTO audit VALUES(13,7,'system',0,'assigned',NULL,'9','2026-11-21T08:47:27.565217+00:00');
INSERT INTO audit VALUES(14,8,'client',8,'created',NULL,'open','2026-11-21T08:29:41.965217+00:00');
INSERT INTO audit VALUES(15,8,'system',0,'assigned',NULL,'4','2026-11-21T08:29:41.965217+00:00');
INSERT INTO audit VALUES(16,9,'client',9,'created',NULL,'open','2026-11-21T08:11:56.365217+00:00');
INSERT INTO audit VALUES(17,9,'system',0,'assigned',NULL,'2','2026-11-21T08:11:56.365217+00:00');
INSERT INTO audit VALUES(18,10,'client',10,'created',NULL,'open','2026-11-21T08:42:10.765217+00:00');
INSERT INTO audit VALUES(19,10,'system',0,'assigned',NULL,'7','2026-11-21T08:42:10.765217+00:00');
INSERT INTO audit VALUES(20,11,'client',1,'created',NULL,'open','2026-11-21T08:24:25.165217+00:00');
INSERT INTO audit VALUES(21,12,'client',2,'created',NULL,'open','2026-11-21T07:37:01.165217+00:00');
INSERT INTO audit VALUES(22,12,'system',0,'assigned',NULL,'7','2026-11-21T07:37:01.165217+00:00');
INSERT INTO audit VALUES(23,13,'client',3,'created',NULL,'open','2026-11-21T07:15:32.365217+00:00');
INSERT INTO audit VALUES(24,13,'system',0,'assigned',NULL,'4','2026-11-21T07:15:32.365217+00:00');
INSERT INTO audit VALUES(25,14,'client',4,'created',NULL,'open','2026-11-21T06:04:29.965217+00:00');
INSERT INTO audit VALUES(26,14,'system',0,'assigned',NULL,'9','2026-11-21T06:04:29.965217+00:00');
INSERT INTO audit VALUES(27,15,'client',5,'created',NULL,'open','2026-11-21T08:05:27.565217+00:00');
INSERT INTO audit VALUES(28,15,'system',0,'assigned',NULL,'7','2026-11-21T08:05:27.565217+00:00');
INSERT INTO audit VALUES(29,16,'client',6,'created',NULL,'open','2026-11-21T06:54:25.165217+00:00');
INSERT INTO audit VALUES(30,16,'system',0,'assigned',NULL,'2','2026-11-21T06:54:25.165217+00:00');
INSERT INTO audit VALUES(31,17,'client',7,'created',NULL,'open','2026-11-21T05:43:22.765217+00:00');
INSERT INTO audit VALUES(32,17,'system',0,'assigned',NULL,'9','2026-11-21T05:43:22.765217+00:00');
INSERT INTO audit VALUES(33,18,'client',8,'created',NULL,'open','2026-11-21T07:44:20.365217+00:00');
INSERT INTO audit VALUES(34,18,'system',0,'assigned',NULL,'4','2026-11-21T07:44:20.365217+00:00');
INSERT INTO audit VALUES(35,19,'client',9,'created',NULL,'open','2026-11-21T06:33:17.965217+00:00');
INSERT INTO audit VALUES(36,19,'system',0,'assigned',NULL,'2','2026-11-21T06:33:17.965217+00:00');
INSERT INTO audit VALUES(37,20,'client',10,'created',NULL,'open','2026-11-21T08:34:15.565217+00:00');
INSERT INTO audit VALUES(38,20,'system',0,'assigned',NULL,'7','2026-11-21T08:34:15.565217+00:00');
INSERT INTO audit VALUES(39,21,'client',1,'created',NULL,'open','2026-11-21T07:23:13.165217+00:00');
INSERT INTO audit VALUES(40,22,'client',2,'created',NULL,'open','2026-11-21T06:12:10.765217+00:00');
INSERT INTO audit VALUES(41,22,'system',0,'assigned',NULL,'7','2026-11-21T06:12:10.765217+00:00');
INSERT INTO audit VALUES(42,23,'client',3,'created',NULL,'open','2026-11-21T08:13:08.365217+00:00');
INSERT INTO audit VALUES(43,23,'system',0,'assigned',NULL,'4','2026-11-21T08:13:08.365217+00:00');
INSERT INTO audit VALUES(44,24,'client',4,'created',NULL,'open','2026-11-21T04:25:01.165217+00:00');
INSERT INTO audit VALUES(45,24,'system',0,'assigned',NULL,'9','2026-11-21T04:25:01.165217+00:00');
INSERT INTO audit VALUES(46,25,'client',5,'created',NULL,'open','2026-11-21T05:51:03.565217+00:00');
INSERT INTO audit VALUES(47,25,'system',0,'assigned',NULL,'7','2026-11-21T05:51:03.565217+00:00');
INSERT INTO audit VALUES(48,26,'client',6,'created',NULL,'open','2026-11-21T07:52:01.165217+00:00');
INSERT INTO audit VALUES(49,26,'system',0,'assigned',NULL,'2','2026-11-21T07:52:01.165217+00:00');
INSERT INTO audit VALUES(50,27,'client',7,'created',NULL,'open','2026-11-21T06:40:58.765217+00:00');
INSERT INTO audit VALUES(51,27,'system',0,'assigned',NULL,'9','2026-11-21T06:40:58.765217+00:00');
INSERT INTO audit VALUES(52,28,'client',8,'created',NULL,'open','2026-11-21T05:29:56.365217+00:00');
INSERT INTO audit VALUES(53,28,'system',0,'assigned',NULL,'4','2026-11-21T05:29:56.365217+00:00');
INSERT INTO audit VALUES(54,29,'client',9,'created',NULL,'open','2026-11-21T07:30:53.965217+00:00');
INSERT INTO audit VALUES(55,29,'system',0,'assigned',NULL,'2','2026-11-21T07:30:53.965217+00:00');
INSERT INTO audit VALUES(56,30,'client',10,'created',NULL,'open','2026-11-21T06:19:51.565217+00:00');
INSERT INTO audit VALUES(57,30,'system',0,'assigned',NULL,'7','2026-11-21T06:19:51.565217+00:00');
INSERT INTO audit VALUES(58,31,'client',1,'created',NULL,'open','2026-11-21T08:20:49.165217+00:00');
INSERT INTO audit VALUES(59,32,'client',2,'created',NULL,'open','2026-11-21T07:09:46.765217+00:00');
INSERT INTO audit VALUES(60,32,'system',0,'assigned',NULL,'7','2026-11-21T07:09:46.765217+00:00');
INSERT INTO audit VALUES(61,33,'client',3,'created',NULL,'open','2026-11-21T05:58:44.365217+00:00');
INSERT INTO audit VALUES(62,33,'system',0,'assigned',NULL,'4','2026-11-21T05:58:44.365217+00:00');
INSERT INTO audit VALUES(63,34,'client',4,'created',NULL,'open','2026-11-21T07:59:41.965217+00:00');
INSERT INTO audit VALUES(64,34,'system',0,'assigned',NULL,'9','2026-11-21T07:59:41.965217+00:00');
INSERT INTO audit VALUES(65,35,'client',5,'created',NULL,'open','2026-11-20T19:31:51.565217+00:00');
INSERT INTO audit VALUES(66,35,'system',0,'assigned',NULL,'7','2026-11-20T19:31:51.565217+00:00');
INSERT INTO audit VALUES(67,36,'client',6,'created',NULL,'open','2026-11-20T08:43:01.165217+00:00');
INSERT INTO audit VALUES(68,36,'system',0,'assigned',NULL,'2','2026-11-20T08:43:01.165217+00:00');
INSERT INTO audit VALUES(69,37,'client',7,'created',NULL,'open','2026-11-21T00:31:22.765217+00:00');
INSERT INTO audit VALUES(70,37,'system',0,'assigned',NULL,'9','2026-11-21T00:31:22.765217+00:00');
INSERT INTO audit VALUES(71,38,'client',8,'created',NULL,'open','2026-11-20T17:25:08.365217+00:00');
INSERT INTO audit VALUES(72,38,'system',0,'assigned',NULL,'4','2026-11-20T17:25:08.365217+00:00');
INSERT INTO audit VALUES(73,39,'client',9,'created',NULL,'open','2026-11-21T05:30:53.965217+00:00');
INSERT INTO audit VALUES(74,39,'system',0,'assigned',NULL,'2','2026-11-21T05:30:53.965217+00:00');
INSERT INTO audit VALUES(75,40,'client',10,'created',NULL,'open','2026-11-20T22:24:39.565217+00:00');
INSERT INTO audit VALUES(76,40,'system',0,'assigned',NULL,'7','2026-11-20T22:24:39.565217+00:00');
INSERT INTO audit VALUES(77,41,'client',1,'created',NULL,'open','2026-11-20T15:18:25.165217+00:00');
INSERT INTO audit VALUES(78,42,'client',2,'created',NULL,'open','2026-11-21T03:24:10.765217+00:00');
INSERT INTO audit VALUES(79,42,'system',0,'assigned',NULL,'7','2026-11-21T03:24:10.765217+00:00');
INSERT INTO audit VALUES(80,43,'client',3,'created',NULL,'open','2026-11-20T20:17:56.365217+00:00');
INSERT INTO audit VALUES(81,43,'system',0,'assigned',NULL,'4','2026-11-20T20:17:56.365217+00:00');
INSERT INTO audit VALUES(82,44,'client',4,'created',NULL,'open','2026-11-20T13:11:41.965217+00:00');
INSERT INTO audit VALUES(83,44,'system',0,'assigned',NULL,'9','2026-11-20T13:11:41.965217+00:00');
INSERT INTO audit VALUES(84,45,'client',5,'created',NULL,'open','2026-11-21T01:17:27.565217+00:00');
INSERT INTO audit VALUES(85,45,'system',0,'assigned',NULL,'7','2026-11-21T01:17:27.565217+00:00');
INSERT INTO audit VALUES(86,46,'client',6,'created',NULL,'open','2026-11-20T18:11:13.165217+00:00');
INSERT INTO audit VALUES(87,46,'system',0,'assigned',NULL,'2','2026-11-20T18:11:13.165217+00:00');
INSERT INTO audit VALUES(88,47,'client',7,'created',NULL,'open','2026-11-21T06:16:58.765217+00:00');
INSERT INTO audit VALUES(89,47,'system',0,'assigned',NULL,'9','2026-11-21T06:16:58.765217+00:00');
INSERT INTO audit VALUES(90,48,'client',8,'created',NULL,'open','2026-11-20T08:31:01.165217+00:00');
INSERT INTO audit VALUES(91,48,'system',0,'assigned',NULL,'4','2026-11-20T08:31:01.165217+00:00');
INSERT INTO audit VALUES(92,49,'client',9,'created',NULL,'open','2026-11-20T16:04:29.965217+00:00');
INSERT INTO audit VALUES(93,49,'system',0,'assigned',NULL,'2','2026-11-20T16:04:29.965217+00:00');
INSERT INTO audit VALUES(94,50,'client',10,'created',NULL,'open','2026-11-21T04:10:15.565217+00:00');
INSERT INTO audit VALUES(95,50,'system',0,'assigned',NULL,'7','2026-11-21T04:10:15.565217+00:00');
INSERT INTO audit VALUES(96,51,'client',1,'created',NULL,'open','2026-11-20T21:04:01.165217+00:00');
INSERT INTO audit VALUES(97,52,'client',2,'created',NULL,'open','2026-11-20T13:57:46.765217+00:00');
INSERT INTO audit VALUES(98,52,'system',0,'assigned',NULL,'7','2026-11-20T13:57:46.765217+00:00');
INSERT INTO audit VALUES(99,53,'client',3,'created',NULL,'open','2026-11-21T02:03:32.365217+00:00');
INSERT INTO audit VALUES(100,53,'system',0,'assigned',NULL,'4','2026-11-21T02:03:32.365217+00:00');
INSERT INTO audit VALUES(101,54,'client',4,'created',NULL,'open','2026-11-20T18:57:17.965217+00:00');
INSERT INTO audit VALUES(102,54,'system',0,'assigned',NULL,'9','2026-11-20T18:57:17.965217+00:00');
INSERT INTO audit VALUES(103,55,'client',5,'created',NULL,'open','2026-11-20T11:51:03.565217+00:00');
INSERT INTO audit VALUES(104,55,'system',0,'assigned',NULL,'7','2026-11-20T11:51:03.565217+00:00');
INSERT INTO audit VALUES(105,56,'client',6,'created',NULL,'open','2026-11-20T23:56:49.165217+00:00');
INSERT INTO audit VALUES(106,56,'system',0,'assigned',NULL,'2','2026-11-20T23:56:49.165217+00:00');
INSERT INTO audit VALUES(107,57,'client',7,'created',NULL,'open','2026-11-20T16:50:34.765217+00:00');
INSERT INTO audit VALUES(108,57,'system',0,'assigned',NULL,'9','2026-11-20T16:50:34.765217+00:00');
INSERT INTO audit VALUES(109,58,'client',8,'created',NULL,'open','2026-11-21T04:56:20.365217+00:00');
INSERT INTO audit VALUES(110,58,'system',0,'assigned',NULL,'4','2026-11-21T04:56:20.365217+00:00');
INSERT INTO audit VALUES(111,59,'client',9,'created',NULL,'open','2026-11-20T21:50:05.965217+00:00');
INSERT INTO audit VALUES(112,59,'system',0,'assigned',NULL,'2','2026-11-20T21:50:05.965217+00:00');
INSERT INTO audit VALUES(113,60,'client',10,'created',NULL,'open','2026-11-20T08:49:01.165217+00:00');
INSERT INTO audit VALUES(114,60,'system',0,'assigned',NULL,'7','2026-11-20T08:49:01.165217+00:00');
INSERT INTO audit VALUES(115,61,'client',1,'created',NULL,'open','2026-11-19T09:04:01.165217+00:00');
INSERT INTO audit VALUES(116,61,'system',0,'assigned',NULL,'2','2026-11-19T09:04:01.165217+00:00');
INSERT INTO audit VALUES(117,61,'agent',2,'status_change','open','solved','2026-11-19T09:04:01.165217+00:00');
INSERT INTO audit VALUES(118,62,'client',2,'created',NULL,'open','2026-11-19T10:16:01.165217+00:00');
INSERT INTO audit VALUES(119,62,'system',0,'assigned',NULL,'7','2026-11-19T10:16:01.165217+00:00');
INSERT INTO audit VALUES(120,62,'agent',7,'status_change','open','solved','2026-11-19T10:16:01.165217+00:00');
INSERT INTO audit VALUES(121,63,'client',3,'created',NULL,'open','2026-11-19T11:28:01.165217+00:00');
INSERT INTO audit VALUES(122,63,'system',0,'assigned',NULL,'4','2026-11-19T11:28:01.165217+00:00');
INSERT INTO audit VALUES(123,63,'agent',4,'status_change','open','solved','2026-11-19T11:28:01.165217+00:00');
INSERT INTO audit VALUES(124,64,'client',4,'created',NULL,'open','2026-11-19T12:40:01.165217+00:00');
INSERT INTO audit VALUES(125,64,'system',0,'assigned',NULL,'9','2026-11-19T12:40:01.165217+00:00');
INSERT INTO audit VALUES(126,64,'agent',9,'status_change','open','solved','2026-11-19T12:40:01.165217+00:00');
INSERT INTO audit VALUES(127,65,'client',5,'created',NULL,'open','2026-11-19T13:52:01.165217+00:00');
INSERT INTO audit VALUES(128,65,'system',0,'assigned',NULL,'7','2026-11-19T13:52:01.165217+00:00');
INSERT INTO audit VALUES(129,65,'agent',7,'status_change','open','solved','2026-11-19T13:52:01.165217+00:00');
INSERT INTO audit VALUES(130,66,'client',6,'created',NULL,'open','2026-11-19T15:04:01.165217+00:00');
INSERT INTO audit VALUES(131,66,'system',0,'assigned',NULL,'2','2026-11-19T15:04:01.165217+00:00');
INSERT INTO audit VALUES(132,66,'agent',2,'status_change','open','solved','2026-11-19T15:04:01.165217+00:00');
INSERT INTO audit VALUES(133,67,'client',7,'created',NULL,'open','2026-11-19T16:16:01.165217+00:00');
INSERT INTO audit VALUES(134,67,'system',0,'assigned',NULL,'9','2026-11-19T16:16:01.165217+00:00');
INSERT INTO audit VALUES(135,67,'agent',9,'status_change','open','solved','2026-11-19T16:16:01.165217+00:00');
INSERT INTO audit VALUES(136,68,'client',8,'created',NULL,'open','2026-11-19T17:28:01.165217+00:00');
INSERT INTO audit VALUES(137,68,'system',0,'assigned',NULL,'4','2026-11-19T17:28:01.165217+00:00');
INSERT INTO audit VALUES(138,68,'agent',4,'status_change','open','solved','2026-11-19T17:28:01.165217+00:00');
INSERT INTO audit VALUES(139,69,'client',9,'created',NULL,'open','2026-11-19T18:40:01.165217+00:00');
INSERT INTO audit VALUES(140,69,'system',0,'assigned',NULL,'2','2026-11-19T18:40:01.165217+00:00');
INSERT INTO audit VALUES(141,69,'agent',2,'status_change','open','solved','2026-11-19T18:40:01.165217+00:00');
INSERT INTO audit VALUES(142,70,'client',10,'created',NULL,'open','2026-11-19T19:52:01.165217+00:00');
INSERT INTO audit VALUES(143,70,'system',0,'assigned',NULL,'7','2026-11-19T19:52:01.165217+00:00');
INSERT INTO audit VALUES(144,70,'agent',7,'status_change','open','solved','2026-11-19T19:52:01.165217+00:00');
INSERT INTO audit VALUES(145,71,'client',1,'created',NULL,'open','2026-11-19T21:04:01.165217+00:00');
INSERT INTO audit VALUES(146,71,'system',0,'assigned',NULL,'2','2026-11-19T21:04:01.165217+00:00');
INSERT INTO audit VALUES(147,71,'agent',2,'status_change','open','solved','2026-11-19T21:04:01.165217+00:00');
INSERT INTO audit VALUES(148,72,'client',2,'created',NULL,'open','2026-11-19T22:16:01.165217+00:00');
INSERT INTO audit VALUES(149,72,'system',0,'assigned',NULL,'7','2026-11-19T22:16:01.165217+00:00');
INSERT INTO audit VALUES(150,72,'agent',7,'status_change','open','solved','2026-11-19T22:16:01.165217+00:00');
INSERT INTO audit VALUES(151,73,'client',3,'created',NULL,'open','2026-11-19T23:28:01.165217+00:00');
INSERT INTO audit VALUES(152,73,'system',0,'assigned',NULL,'4','2026-11-19T23:28:01.165217+00:00');
INSERT INTO audit VALUES(153,73,'agent',4,'status_change','open','solved','2026-11-19T23:28:01.165217+00:00');
INSERT INTO audit VALUES(154,74,'client',4,'created',NULL,'open','2026-11-20T00:40:01.165217+00:00');
INSERT INTO audit VALUES(155,74,'system',0,'assigned',NULL,'9','2026-11-20T00:40:01.165217+00:00');
INSERT INTO audit VALUES(156,74,'agent',9,'status_change','open','solved','2026-11-20T00:40:01.165217+00:00');
INSERT INTO audit VALUES(157,75,'client',5,'created',NULL,'open','2026-11-20T01:52:01.165217+00:00');
INSERT INTO audit VALUES(158,75,'system',0,'assigned',NULL,'7','2026-11-20T01:52:01.165217+00:00');
INSERT INTO audit VALUES(159,75,'agent',7,'status_change','open','solved','2026-11-20T01:52:01.165217+00:00');
INSERT INTO audit VALUES(160,76,'client',6,'created',NULL,'open','2026-11-20T03:04:01.165217+00:00');
INSERT INTO audit VALUES(161,76,'system',0,'assigned',NULL,'2','2026-11-20T03:04:01.165217+00:00');
INSERT INTO audit VALUES(162,76,'agent',2,'status_change','open','solved','2026-11-20T03:04:01.165217+00:00');
INSERT INTO audit VALUES(163,77,'client',7,'created',NULL,'open','2026-11-20T04:16:01.165217+00:00');
INSERT INTO audit VALUES(164,77,'system',0,'assigned',NULL,'9','2026-11-20T04:16:01.165217+00:00');
INSERT INTO audit VALUES(165,77,'agent',9,'status_change','open','solved','2026-11-20T04:16:01.165217+00:00');
INSERT INTO audit VALUES(166,78,'client',8,'created',NULL,'open','2026-11-20T05:28:01.165217+00:00');
INSERT INTO audit VALUES(167,78,'system',0,'assigned',NULL,'4','2026-11-20T05:28:01.165217+00:00');
INSERT INTO audit VALUES(168,78,'agent',4,'status_change','open','solved','2026-11-20T05:28:01.165217+00:00');
INSERT INTO audit VALUES(169,79,'client',9,'created',NULL,'open','2026-11-20T06:40:01.165217+00:00');
INSERT INTO audit VALUES(170,79,'system',0,'assigned',NULL,'2','2026-11-20T06:40:01.165217+00:00');
INSERT INTO audit VALUES(171,79,'agent',2,'status_change','open','solved','2026-11-20T06:40:01.165217+00:00');
INSERT INTO audit VALUES(172,80,'client',10,'created',NULL,'open','2026-11-20T07:52:01.165217+00:00');
INSERT INTO audit VALUES(173,80,'system',0,'assigned',NULL,'7','2026-11-20T07:52:01.165217+00:00');
INSERT INTO audit VALUES(174,80,'agent',7,'status_change','open','solved','2026-11-20T07:52:01.165217+00:00');
INSERT INTO audit VALUES(175,81,'client',1,'created',NULL,'open','2026-11-20T09:04:01.165217+00:00');
INSERT INTO audit VALUES(176,81,'system',0,'assigned',NULL,'2','2026-11-20T09:04:01.165217+00:00');
INSERT INTO audit VALUES(177,81,'agent',2,'status_change','solved','closed','2026-11-20T09:04:01.165217+00:00');
INSERT INTO audit VALUES(178,82,'client',2,'created',NULL,'open','2026-11-20T10:16:01.165217+00:00');
INSERT INTO audit VALUES(179,82,'system',0,'assigned',NULL,'7','2026-11-20T10:16:01.165217+00:00');
INSERT INTO audit VALUES(180,82,'agent',7,'status_change','solved','closed','2026-11-20T10:16:01.165217+00:00');
INSERT INTO audit VALUES(181,83,'client',3,'created',NULL,'open','2026-11-20T11:28:01.165217+00:00');
INSERT INTO audit VALUES(182,83,'system',0,'assigned',NULL,'4','2026-11-20T11:28:01.165217+00:00');
INSERT INTO audit VALUES(183,83,'agent',4,'status_change','solved','closed','2026-11-20T11:28:01.165217+00:00');
INSERT INTO audit VALUES(184,84,'client',4,'created',NULL,'open','2026-11-20T12:40:01.165217+00:00');
INSERT INTO audit VALUES(185,84,'system',0,'assigned',NULL,'9','2026-11-20T12:40:01.165217+00:00');
INSERT INTO audit VALUES(186,84,'agent',9,'status_change','solved','closed','2026-11-20T12:40:01.165217+00:00');
INSERT INTO audit VALUES(187,85,'client',5,'created',NULL,'open','2026-11-20T13:52:01.165217+00:00');
INSERT INTO audit VALUES(188,85,'system',0,'assigned',NULL,'7','2026-11-20T13:52:01.165217+00:00');
INSERT INTO audit VALUES(189,85,'agent',7,'status_change','solved','closed','2026-11-20T13:52:01.165217+00:00');
INSERT INTO audit VALUES(190,86,'client',6,'created',NULL,'open','2026-11-20T15:04:01.165217+00:00');
INSERT INTO audit VALUES(191,86,'system',0,'assigned',NULL,'2','2026-11-20T15:04:01.165217+00:00');
INSERT INTO audit VALUES(192,86,'agent',2,'status_change','solved','closed','2026-11-20T15:04:01.165217+00:00');
INSERT INTO audit VALUES(193,87,'client',7,'created',NULL,'open','2026-11-20T16:16:01.165217+00:00');
INSERT INTO audit VALUES(194,87,'system',0,'assigned',NULL,'9','2026-11-20T16:16:01.165217+00:00');
INSERT INTO audit VALUES(195,87,'agent',9,'status_change','solved','closed','2026-11-20T16:16:01.165217+00:00');
INSERT INTO audit VALUES(196,88,'client',8,'created',NULL,'open','2026-11-20T17:28:01.165217+00:00');
INSERT INTO audit VALUES(197,88,'system',0,'assigned',NULL,'4','2026-11-20T17:28:01.165217+00:00');
INSERT INTO audit VALUES(198,88,'agent',4,'status_change','solved','closed','2026-11-20T17:28:01.165217+00:00');
INSERT INTO audit VALUES(199,89,'client',9,'created',NULL,'open','2026-11-20T18:40:01.165217+00:00');
INSERT INTO audit VALUES(200,89,'system',0,'assigned',NULL,'2','2026-11-20T18:40:01.165217+00:00');
INSERT INTO audit VALUES(201,89,'agent',2,'status_change','solved','closed','2026-11-20T18:40:01.165217+00:00');
INSERT INTO audit VALUES(202,90,'client',10,'created',NULL,'open','2026-11-20T19:52:01.165217+00:00');
INSERT INTO audit VALUES(203,90,'system',0,'assigned',NULL,'7','2026-11-20T19:52:01.165217+00:00');
INSERT INTO audit VALUES(204,90,'agent',7,'status_change','solved','closed','2026-11-20T19:52:01.165217+00:00');
INSERT INTO audit VALUES(205,91,'client',1,'created',NULL,'open','2026-11-20T21:04:01.165217+00:00');
INSERT INTO audit VALUES(206,91,'system',0,'assigned',NULL,'1','2026-11-20T21:04:01.165217+00:00');
INSERT INTO audit VALUES(207,91,'system',0,'escalated','low','normal','2026-11-20T21:04:01.165217+00:00');
INSERT INTO audit VALUES(208,92,'client',2,'created',NULL,'open','2026-11-20T22:16:01.165217+00:00');
INSERT INTO audit VALUES(209,92,'system',0,'assigned',NULL,'1','2026-11-20T22:16:01.165217+00:00');
INSERT INTO audit VALUES(210,92,'system',0,'escalated','low','normal','2026-11-20T22:16:01.165217+00:00');
INSERT INTO audit VALUES(211,93,'client',3,'created',NULL,'open','2026-11-20T23:28:01.165217+00:00');
INSERT INTO audit VALUES(212,93,'system',0,'assigned',NULL,'1','2026-11-20T23:28:01.165217+00:00');
INSERT INTO audit VALUES(213,93,'system',0,'escalated','low','normal','2026-11-20T23:28:01.165217+00:00');
INSERT INTO audit VALUES(214,94,'client',4,'created',NULL,'open','2026-11-21T00:40:01.165217+00:00');
INSERT INTO audit VALUES(215,94,'system',0,'assigned',NULL,'1','2026-11-21T00:40:01.165217+00:00');
INSERT INTO audit VALUES(216,94,'system',0,'escalated','low','normal','2026-11-21T00:40:01.165217+00:00');
INSERT INTO audit VALUES(217,95,'client',5,'created',NULL,'open','2026-11-21T01:52:01.165217+00:00');
INSERT INTO audit VALUES(218,95,'system',0,'assigned',NULL,'1','2026-11-21T01:52:01.165217+00:00');
INSERT INTO audit VALUES(219,95,'system',0,'escalated','low','normal','2026-11-21T01:52:01.165217+00:00');
INSERT INTO audit VALUES(220,96,'client',6,'created',NULL,'open','2026-11-21T03:04:01.165217+00:00');
INSERT INTO audit VALUES(221,96,'system',0,'assigned',NULL,'1','2026-11-21T03:04:01.165217+00:00');
INSERT INTO audit VALUES(222,96,'system',0,'escalated','low','normal','2026-11-21T03:04:01.165217+00:00');
INSERT INTO audit VALUES(223,97,'client',7,'created',NULL,'open','2026-11-21T04:16:01.165217+00:00');
INSERT INTO audit VALUES(224,97,'system',0,'assigned',NULL,'1','2026-11-21T04:16:01.165217+00:00');
INSERT INTO audit VALUES(225,97,'system',0,'escalated','low','normal','2026-11-21T04:16:01.165217+00:00');
INSERT INTO audit VALUES(226,98,'client',8,'created',NULL,'open','2026-11-21T05:28:01.165217+00:00');
INSERT INTO audit VALUES(227,98,'system',0,'assigned',NULL,'1','2026-11-21T05:28:01.165217+00:00');
INSERT INTO audit VALUES(228,98,'system',0,'escalated','low','normal','2026-11-21T05:28:01.165217+00:00');
INSERT INTO audit VALUES(229,99,'client',9,'created',NULL,'open','2026-11-21T06:40:01.165217+00:00');
INSERT INTO audit VALUES(230,99,'system',0,'assigned',NULL,'1','2026-11-21T06:40:01.165217+00:00');
INSERT INTO audit VALUES(231,99,'system',0,'escalated','low','normal','2026-11-21T06:40:01.165217+00:00');
INSERT INTO audit VALUES(232,100,'client',10,'created',NULL,'open','2026-11-21T07:52:01.165217+00:00');
INSERT INTO audit VALUES(233,100,'system',0,'assigned',NULL,'1','2026-11-21T07:52:01.165217+00:00');
INSERT INTO audit VALUES(234,100,'system',0,'escalated','low','normal','2026-11-21T07:52:01.165217+00:00');
CREATE TABLE system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
INSERT INTO system_settings VALUES('last_assigned_agent_id','2');
CREATE TABLE sessions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    token_hash  TEXT NOT NULL UNIQUE,      -- SHA-256 of the token; raw token never stored
    user_type   TEXT NOT NULL CHECK (user_type IN ('client', 'agent')),
    user_id     INTEGER NOT NULL,          -- references clients.id or agents.id
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,        -- login time + 8 hours
    revoked_at  TIMESTAMP                  -- set on logout; NULL = active
);
CREATE TABLE agent_clients (
    agent_id    INTEGER NOT NULL,
    client_id   INTEGER NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (agent_id, client_id),
    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);
INSERT INTO agent_clients VALUES(2,1,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(5,1,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(3,2,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(7,2,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(4,3,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(8,3,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(5,4,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(9,4,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(7,5,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(10,5,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(8,6,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(2,6,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(9,7,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(3,7,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(10,8,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(4,8,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(2,9,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(5,9,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(3,10,'2026-11-21 09:04:01');
INSERT INTO agent_clients VALUES(7,10,'2026-11-21 09:04:01');
INSERT INTO sqlite_sequence VALUES('statuses',6);
INSERT INTO sqlite_sequence VALUES('priorities',4);
INSERT INTO sqlite_sequence VALUES('users',10);
INSERT INTO sqlite_sequence VALUES('clients',10);
INSERT INTO sqlite_sequence VALUES('agents',10);
INSERT INTO sqlite_sequence VALUES('tickets',100);
INSERT INTO sqlite_sequence VALUES('worksheet',94);
INSERT INTO sqlite_sequence VALUES('audit',234);
INSERT INTO sqlite_sequence VALUES('messages',216);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_agent ON tickets(agent_id);
CREATE INDEX idx_tickets_client ON tickets(client_id);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_messages_ticket_order ON messages(ticket_id, created_at ASC, id ASC);
CREATE INDEX idx_worksheet_ticket ON worksheet(ticket_id);
CREATE INDEX idx_worksheet_agent ON worksheet(agent_id);
CREATE INDEX idx_audit_ticket ON audit(ticket_id);
CREATE INDEX idx_sessions_user ON sessions(user_type, user_id);
CREATE INDEX idx_sessions_lookup ON sessions(token_hash, revoked_at, expires_at);
CREATE INDEX idx_agent_clients_client ON agent_clients(client_id);
COMMIT;
