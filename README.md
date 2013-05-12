[![Build Status](https://secure.travis-ci.org/camelmasa/ec2-mini.png)](http://travis-ci.org/camelmasa/ec2-mini)

Install
---

`gem install ec2-mini`

Setup
---

vi ~/.ec2-mini

```
access_key_id: 'XXX'
secret_access_key: 'XXX'
region: 'XXX'
```

Command
---

`ec2-mini [role] [command]`

Example
---

`ec2-mini ap-server backup`

`ec2-mini ap-server +3`

`ec2-mini ap-server -1`

`ec2-mini ap-server count`
