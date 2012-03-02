
emailTemplate = ({publicUrl, adminUrl, remoteUrl, name}) ->
  subject = "New Pahvi: #{ name }"
  body = """

Hi!

You have created a Pahvi named "#{ name }"

You can edit it by using this url:

#{ adminUrl }

Share the presentation using this url (read-only):

#{ publicUrl }

Remote controller presentations with this:

#{ remoteUrl }
Can be used to control the presentation remotely from your mobile phone.


Thanks for trying out Pahvi. Feel free to contact us at dev@opinsys.fi if you
have any questions.


"""

  subject: subject
  body: body.trim()


exports.emailTemplate = emailTemplate
