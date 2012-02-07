
emailTemplate = ({publicUrl, adminUrl, name}) ->
  subject = "New Pahvi: #{ name }"
  body = """

Hi!

You have created a Pahvi named "#{ name }"

You can edit it by using this url:

#{ adminUrl }

Share the presentation using this url (read-only):

#{ publicUrl }

"""

  subject: subject
  body: body.trim()


exports.emailTemplate = emailTemplate
