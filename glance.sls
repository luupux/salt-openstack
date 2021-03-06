# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# All Rights Reserved.
# Copyright 2013 Yazz D. Atlas <yazz.atlas@hp.com>
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

include:
  - openstack.mysql
  - openstack.memcached
  - openstack.root-scripts
  - openstack.glance.scripts

glance-pkgs:
  pkg.installed:
    - names:
      - glance
      - glance-api
      - glance-common
      - glance-registry
      - python-glanceclient
    - require:
      - service.running: mysql
      - pkg.installed: python-mysqldb
      - pkg.installed: rabbitmq-server
      - mysql_database.present: glance
      - mysql_grants.present: glance
      - mysql_user.present: glance
      - cmd.run: glance-grant-wildcard
      - cmd.run: glance-grant-localhost
      - cmd.run: glance-grant-star


glance-services:
  service:
    - running
    - enable: True
    - names:
      - glance-api
      - glance-registry
    - require:
      - pkg.installed: glance-pkgs
      - service.running: mysql
    - watch:
      - file.recurse: /etc/glance

glance-setup:
  cmd.run:
    - unless: test -f /etc/setup-done-glance
    - name: /root/scripts/glance-setup.sh
    - require:
      - file.recurse: /etc/glance
      - service.running: mysql
      - pkg.installed: glance-pkgs

/etc/glance:
  file:
    - recurse
    - source: salt://openstack/glance
    - template: jinja
    - require:
      - pkg.installed: glance-pkgs
      - file.recurse: /root/scripts
    - context:
        secrets: {{ pillar['secrets'] }}
        cinder: {{ pillar['cinder'] }}
        glance: {{ pillar['glance'] }}
        keystone: {{ pillar['keystone'] }}
        nova: {{ pillar['nova'] }}
        endpoints: {{ pillar['endpoints'] }}
