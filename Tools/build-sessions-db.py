#!/usr/bin/env python

import os
import sqlite3
import yaml

# Specify input and output paths
FILE_ROOT = os.path.dirname(__file__)
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

# Create the output DB
conn = sqlite3.connect(outpath)
c = conn.cursor()

# Create a table using full text search
c.execute('CREATE VIRTUAL TABLE session_fts USING fts4(session_number, title, description)')
c.execute('CREATE TABLE session (year integer, session_number integer, title text, description text, track text)')

uid = 0
for year in [2014, 2013, 2012]:
    relative_path = '../Vendor/wwdc-session-transcripts/%d/_sessions.yml' % year
    inpath = os.path.join(FILE_ROOT, relative_path)
    data = yaml.load(open(inpath))
    for session_number, session_info in data.items():
        title = session_info[':title']
        description = session_info[':description']
        track = session_info[':track']
        uid += 1
        
        insert_query = 'INSERT INTO session_fts (docid, session_number, title, description) values (?, ?, ?, ?)'
        params = (uid, session_number, title, description)
        c.execute(insert_query, params)
        
        insert_query = 'INSERT INTO session (rowid, year, session_number, title, description, track) values (?, ?, ?, ?, ?, ?)'
        params = (uid, year, session_number, title, description, track)
        c.execute(insert_query, params)
    
conn.commit()
conn.close()