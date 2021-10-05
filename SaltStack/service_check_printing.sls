disable_SpoolerSvc:
  service.dead:
    - name: 'spooler'
    - enable: False
# This will check to see if the spooler service is stopped and will stop if running.