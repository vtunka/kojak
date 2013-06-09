insert into users (name, status, usertype) values ('koji', 0, 0);
insert into user_perms (user_id, perm_id, creator_id) values (1, 1, 1);
insert into users (name, status, usertype) values ('kojiadmin', 0, 0);
insert into user_perms (user_id, perm_id, creator_id) values (2, 1, 1);
insert into users (name, status, usertype) values ('kojira', 0, 3);
insert into user_perms (user_id, perm_id, creator_id) values (3, 1, 1);
insert into users (name, status, usertype) values ('kojibuilder1', 0, 1);
insert into user_perms (user_id, perm_id, creator_id) values (4, 1, 1);
insert into users (name, status, usertype) values ('kojibuilder1.localdomain', 0, 1);
insert into user_perms (user_id, perm_id, creator_id) values (5, 1, 1);
\q
