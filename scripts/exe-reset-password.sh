#!/bin/sh
EMAIL=$1
NEWPW=$2
HASH=$(bun -e "import bcrypt from 'bcryptjs'; console.log(bcrypt.hashSync('$NEWPW', 10));")
bun -e "
import { Database } from 'bun:sqlite';
const db = new Database('/mnt/data/exelearning.db');
db.run(\"UPDATE users SET password = ? WHERE email = '$EMAIL'\", ['$HASH']);
console.log('Password reset for $EMAIL');
db.close();
"
