from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
from selenium import webdriver
import time

baseurl = 'http://www.klwines.com/Products/r?d=0&r=58&p=0&o=8&t=&z=False'
driverpath = "./chromedriver"

driver = webdriver.Chrome(executable_path=driverpath)

driver.get(baseurl)
time.sleep(2)
driver.find_element_by_xpath("//a[@title='View More »']").click() #click 'view more'
time.sleep(2)
bsobject = BeautifulSoup(driver.page_source, 'html.parser')
driver.close()

variety = bsobject.find('div', {'class': 'col-a'})

typelist = variety.ul.findAll('li')# findAll li tags in col-a
types = [type.a.getText() for type in typelist]
typeurls = [type.a['href'] for type in typelist]

for i in range(len(typeurls)):
    url = typeurls[i]
    deadpage = 0
    p = 0
    drinknames = []
    drinkprices = []
    drinkdescs = []
    drinktype = []
    while deadpage == 0:
        web = urlopen('http://www.klwines.com' + url + '&p=' + str(p)).read()
        bsobject = BeautifulSoup(web, 'html.parser')
        drinklist = bsobject.find_all('div',{'class':'result clearfix'})
        if len(drinklist) == 0:
            deadpage = 1
        else:
            for drink in drinklist:
                drinktype.append(types[i])
                desc = drink.find('div', {'class': 'result-desc'})
                drinknames.append(desc.a.getText())
                spans = desc.p.findAll('span')
                drinkdescs.append(' '.join([span.getText() for span in spans])) #all spans, get text, merge text
                drinkprices.append(drink.find('div', {'class': 'result-info'}).find('strong').getText())
        p += 50
        print('Scraping ' + types[i] + ', on drink number ' + str(p))
    df = pd.DataFrame([drinktype, drinknames, drinkdescs, drinkprices])
    df = df.transpose()
    with open('klspirits.csv', 'a') as csvfile:
        df.to_csv(csvfile, header=False, index=False)