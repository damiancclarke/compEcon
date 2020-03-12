#  Scrape_xkcd_bs v0.01          damiancclarke             yyyy-mm-dd:2020-03-13
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# Syntax is: python Scrape_xkcd_bs.py
#  
# This file scrapes xkcd to find the total number of comics, and the prints out 
# each comic's name.  It is not meant to be remarkably useful, rather it simply
# demonstrates the use of Python's urllib2 library, as well as a simple example
# of html parsing with BeautifulSoup.

#*******************************************************************************
# (1) Import required packages, set-up names used in urls
#*******************************************************************************
import urllib2
import re
from bs4 import BeautifulSoup

target = 'http://www.xkcd.com'

#*******************************************************************************
# (2) Scrape target url and find the last comic number (num)
#*******************************************************************************
response = urllib2.urlopen(target)

for line in response:
        print line
        search = re.search('Permanent link to this comic:', line)
	if search!=None:
		lastcomic=re.findall('\d*', line)
                
for item in lastcomic:
	if len(item)>0:
		num = int(item)

#*******************************************************************************
# (3) Loop through all comics, finding each comic's title or capturing errors
#*******************************************************************************
output = open('xkcd_names_bs.txt', 'w')
output.write('Comic, Number, Title \n')

for append in range(1, num+1):
	url = target + '/' + str(append)
	try:
		response = BeautifulSoup(urllib2.urlopen(url),'html.parser')
                search = response.title.string
                
                clean  = search[6:]
		print str(append) + '\t' + clean
		output.write('xkcd,' + str(append) + ',' + clean + '\n')
	except urllib2.HTTPError, e:
		print('%s has http error' % url)
	except urllib2.URLError, e:
		print('%s has url error' % url)

output.close()
