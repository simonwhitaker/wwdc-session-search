#!/usr/bin/env python

import os
import sqlite3
import yaml

# TODO: Currently only loads the 2013 session data

# Specify input and output paths
FILE_ROOT = os.path.dirname(__file__)
inpath = os.path.join(FILE_ROOT, '../Vendor/wwdc-session-transcripts/2013/_sessions.yml')
outpath = os.path.join(FILE_ROOT, '../Assets/sessions.sqlite3')

# Create the output directory if it doesn't exist
try:
    os.makedirs(os.path.dirname(outpath))
except:
    pass

# Remove any existing output DB
try:
    os.remove(outpath)
except:
    pass

# Load the data, create the output DB
data = yaml.load(open(inpath))
conn = sqlite3.connect(outpath)
c = conn.cursor()

# Create a table using full text search
c.execute('CREATE VIRTUAL TABLE session USING fts4(title, description)')

for session_id, session_info in data.items():
    insert_query = 'INSERT INTO session (docid, title, description) values (%d, "%s", "%s")' % (
        int(session_id),
        session_info[':title'],
        session_info[':description'],
    )
    c.execute(insert_query)
    
conn.commit()
conn.close()