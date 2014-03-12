/* create user and the corresponding database
 *
 */

/* create user 'olio' with passwd 'olio' and grant all privileges to it */
create user 'olio'@'%' identified by 'olio';
grant all privileges on *.* to 'olio'@'%' identified by 'olio' with grant option;

/* create database 'olio' */
create database olio;
use olio;

/* create the schema */
\. /opt/schema.sql


