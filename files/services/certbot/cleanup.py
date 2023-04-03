#!/usr/bin/env python3

import sys
import os
import configparser
import logging
import logging.handlers


import requests


logging.basicConfig(filename='/tmp/certbot_validator.log', level=logging.DEBUG)
logger = logging.getLogger("certbot_validator")
logger.addHandler(logging.StreamHandler(sys.stdout))

class GoDaddySSOAuth(requests.auth.AuthBase):
      def __init__(self, api_key, api_secret):
          self.api_key = api_key
          self.api_secret = api_secret
      def __call__(self, r):
          r.headers['Authorization'] = f"sso-key {self.api_key}:{self.api_secret}"
          return r

def setup():
    logger.info("---Begin Certbot cleanup script---")

    config = configparser.ConfigParser()
    godaddy_api_key = ""
    godaddy_api_secret = ""
    config_file = os.path.dirname(os.path.abspath(__file__)) + '/godaddy_config.ini'
    if os.path.isfile(config_file):
        logger.info(f"Using {config_file} as config file for api key/secret.")
        failed_config_read = False
        config = configparser.ConfigParser()
        try:
            config.read(config_file)
        except configparser.MissingSectionHeaderError:
            logger.error("godaddy_config.ini not a valid config file. Missing section header(s).")
            finish(False) 
        if 'default' not in config.sections():
            logger.error("Error reading config file, 'default' section not present.")
            finish(False)
        if 'api_key' not in config['default'].keys():
            logger.error("Error reading config file, 'api_key' not found in 'default' section.")
            failed_config_read = True

        if 'api_secret' not in config['default'].keys():
            logger.error("Error reading config file, 'api_secret' not found in 'default' section")
            failed_config_read = True

        if failed_config_read:
            finish(False)
        godaddy_api_key = config['default']['api_key']
        godaddy_api_secret = config['default']['api_secret']
    else:
        logger.info("Using env vars for api key/secret.")
        failed_env_read = False
        # Look in env vars for GODADDY_API_KEY and GODADDY_API_SECRET
        godaddy_api_key = os.getenv('GODADDY_API_KEY')
        godaddy_api_secret = os.getenv('GODADDY_API_SECRET')
        if godaddy_api_key == None:
            logger.error("GODADDY_API_KEY envrionment variable not set.")
            failed_env_read = True
        if godaddy_api_key == None:
            logger.error("GODADDY_API_SECRET envrionment variable not set.")
            failed_env_read = True
        if failed_env_read:
            finish(False)

    #Get the domain from the CERTBOT_DOMAIN and extract the root domain.
    certbot_domain = os.getenv("CERTBOT_DOMAIN")
    if certbot_domain == None:
        logger.error("CERTBOT_DOMAIN env is not set. If you are not running this script for testing, please set this envionment variable")
        finish(False)
    root_domain = f"{certbot_domain.split('.')[-2]}.{certbot_domain.split('.')[-1]}"

    # Test auth and ensure it is correct
    test_godaddy_auth(godaddy_api_key, godaddy_api_secret, root_domain)

    delete_godaddy_record(godaddy_api_key, godaddy_api_secret, certbot_domain, root_domain)

def test_godaddy_auth(godaddy_api_key, godaddy_api_secret, root_domain):
    test_url = f"https://api.godaddy.com/v1/domains/{root_domain}/records"
    response = requests.get( test_url, auth=GoDaddySSOAuth(godaddy_api_key, godaddy_api_secret))
    if response.status_code != 200:
        logger.error(f"Auth against go daddy api failed with {response.status_code}.")
        finish(False)

def delete_godaddy_record(godaddy_api_key, godaddy_api_secret, certbot_domain, root_domain):
    record_name = "_acme-challenge"

    if certbot_domain != root_domain:
        record_name = f"{record_name}.{certbot_domain.replace('.'+root_domain, '')}"
    
    
    logger.info(f"Deleting record of TXT with name {record_name}")

    godaddy_record_url = f"https://api.godaddy.com/v1/domains/{root_domain}/records/TXT/{record_name}"
    response = requests.delete(godaddy_record_url, auth=GoDaddySSOAuth(godaddy_api_key, godaddy_api_secret))
    if response.content != b'':
        logger.error(f"Request to go daddy failed with {response.content} as the response.")
        finish(False)

    finish(True)


        


def finish(success=True):
    logger.info("---Ending Certbot cleanup script---")
    if success: 
        sys.exit()
    sys.exit(1)

if __name__ == "__main__":
    setup()


