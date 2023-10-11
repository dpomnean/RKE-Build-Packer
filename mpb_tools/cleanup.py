# https://developer.vmware.com/apis/vsphere-automation/v7.0U3/content/api/content/library/item/library_item_id/get/
#!/usr/bin python3

# This script will delete old rancher rke2 image templates in vsphere
import requests
import urllib3
from vmware.vapi.vsphere.client import create_vsphere_client
from com.vmware.content.library_client import ItemModel
import datetime
import argparse
import time
import sys

session = requests.session()
session.verify = False
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def get_template_item(templs):
    main_template = vsphere_client.content.library.Item.get(templs)
    print(main_template)
    print(main_template.name)

    return main_template

# vSphere connection
vsphere_client = create_vsphere_client(
    server=str(sys.argv[1]),
    username=str(sys.argv[2]),
    password=str(sys.argv[3]),
    session=session,
)

# Get all local content libraries
c_libs = vsphere_client.content.LocalLibrary.list()
del_finished = False
update_finished = False
our_library = str(sys.argv[4])
todays_templ = datetime.date.today().strftime("%Y-%m-%d")
i = 0
b = []


for libs in c_libs:
    c_items = vsphere_client.content.library.Item.list(libs)
    print(c_items)

    # Get all template items for rancher_rke2
    for templs in c_items:
        templ_out = get_template_item(templs)
        print(templ_out)

        if "rancher_rke2" in templ_out.name:
            i = i + 1
            b.append(templ_out)


    # Loop list of items so we can make sure theres at least 2 items left
    # Delete templates older than 2 months
    for item in b:
        create_date = item.creation_time.strftime("%Y-%m-%d")
        a = datetime.datetime.strptime(todays_templ,"%Y-%m-%d") - datetime.datetime.strptime(create_date,"%Y-%m-%d")
        print(item)
        
        # 2 months
        if a.days > 60 and len(b) > 2:
            print("DELETE", item.id)
            vsphere_client.content.library.Item.delete(item.id)
            print("deleted...")