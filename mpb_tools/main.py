# https://developer.vmware.com/apis/vsphere-automation/v7.0U3/content/api/content/library/item/library_item_id/get/
#!/usr/bin python3

# Go through vsphere templates and create the golden image template
import requests
import urllib3
from vmware.vapi.vsphere.client import create_vsphere_client
from com.vmware.content.library_client import ItemModel
import datetime
import argparse
import time

session = requests.session()
session.verify = False
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def GetArgs():
    parser = argparse.ArgumentParser(description='Process args for rke2 template stuff')
    parser.add_argument('-s', '--vsphere_host', required=True, action='store',help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True, action='store',help='username')
    parser.add_argument('-p', '--password', required=True, action='store',help='password')
    args = parser.parse_args()
    return args

args = GetArgs()

# vSphere connection
vsphere_client = create_vsphere_client(
    server=args.vsphere_host,
    username=args.username,
    password=args.password,
    session=session,
)

print(vsphere_client)

# Get all local content libraries
c_libs = vsphere_client.content.LocalLibrary.list()
del_finished = False
update_finished = False
our_library = ""
todays_templ = "rancher_rke2-" + datetime.date.today().strftime("%Y-%m-%d")

# Get template definitions
def get_template_item(templs):
    main_template = vsphere_client.content.library.Item.get(templs)
    print(main_template)
    print(main_template.name)

    return main_template


# Go through libraries and find our golden image to delete. This will be replaced by the latest built image.
for libs in c_libs:
    c_items = vsphere_client.content.library.Item.list(libs)
    print(c_items)

    # Loop through templates in current library
    for templs in c_items:
        templ_out = get_template_item(templs)

        # Delete the latest golden image if found. Sadly we can't just replace, that would be too easy.
        if templ_out.name == "rancher_rke2" and not del_finished:
            print("deleting goldenshower image..."+templ_out.id)
            try:
                vsphere_client.content.library.Item.delete(templ_out.id)
                our_library = templ_out.library_id
                del_finished = True
                print("template deleted successfully...")
                time.sleep(5)
            except Exception as e:
                print("issue with deleting image...")
                print(e)
        if del_finished:
            break
    if del_finished:
        break

if del_finished == False:
    print("Something happened, gold image wasnt removed...")
else:
    # Go through the library where our golden image was found and update the last built image to name it 'rancher_rke2'
    c_items = vsphere_client.content.library.Item.list(our_library)
    print(c_items)

    for templs in c_items:
        templ_out = get_template_item(templs)

        if templ_out.name == todays_templ and del_finished:
            print("found the template to clone...")

            lib_item_spec = ItemModel()
            lib_item_spec.name = "rancher_rke2"
            lib_item_spec.description = "Rancher VM RKE 2 Golden Image"
            lib_item_spec.library_id = our_library
            lib_item_spec.type = "ovf"

            print("cloning vm template...")
            try:
                vsphere_client.content.library.Item.copy(templ_out.id, lib_item_spec)
                update_finished = True
                print("clone complete...")
            except Exception as e:
                print("cloning error...")
                print(e)
        if update_finished:
            break
