Handlebars.registerHelper "withif", (obj, options) ->
  if obj then options.fn(obj) else options.inverse(this)

Handlebars.registerHelper 'isOwner', () ->
  Session.get("isOwner")

Handlebars.registerHelper 'owner', () ->
  UserEmailById(Session.get("owner"))

Template.modals.rendered = ->
    $('#revokedModal').on 'revokedEvent',  (e) ->
      $("#revokedModal").modal('show')


Template.docList.documents = ->
  users = [Meteor.userId()]
  Documents.find({$or: [{userId: users[0]}, {invitedUsers: {$in: users}}]})

Template.docList.events =
  "click button": ->
    userId = Meteor.userId()
    Documents.insert({
        title: "untitled",
        userId: userId,
        invitedUsers: [],
        private: false,
        revokePending: [],
      },
      (err, id) ->
        return unless id
        Session.set("document", id)
        Session.set("owner", userId)
        Session.set("isOwner", true)
        Session.set("invitedUsers", [])
      )

Template.docItem.current = ->
  Session.equals("document", @_id)

Template.docItem.events =
  "click a": (e) ->
    e.preventDefault()
    Session.set("document", @_id)
    Session.set("owner", @userId)
    Session.set("isOwner", @userId == Meteor.userId())
    Session.set("invitedUsers", @invitedUsers)

Template.docTitle.title = ->
  # Strange bug https://github.com/meteor/meteor/issues/1447
  Documents.findOne(@substring 0)?.title

Template.docTitle.events =
  "blur #documentName": (e) ->
    id = Session.get('document')
    Documents.update({_id: id}, {$set: {'title': $(e.target).val()}})

Template.editor.docid = ->
  Session.get("document")

Template.editor.events =
  "keydown input": (e) ->
    return unless e.keyCode == 13
    e.preventDefault()

    $(e.target).blur()
    id = Session.get("document")
    Documents.update id,
      title: e.target.value

  "click .delete": (e) ->
    e.preventDefault()
    id = Session.get("document")
    Session.set("document", null)
    Meteor.call "deleteDocument", id

Template.editor.config = ->
  (ace) ->
    # Set some reasonable options on the editor
    ace.setShowPrintMargin(false)
    ace.getSession().setUseWrapMode(true)

Template.collab.invited = ->
  UserEmailsById(Session.get('invitedUsers'))

Template.invites.members = ->
  currentUser = Meteor.userId()
  result = []
  users = Meteor.users.find({})
  users.forEach (user) ->
    result.push(user.emails[0].address) unless user._id is currentUser
  return result

Template.invites.affectedMembers = ->
  Session.get('affectedMembers')

Template.invites.status = ->
  Session.get('status')

Template.invites.rendered = ->
  memberSelect = $('#members-to-invite-select')
  memberSelect.hide()
  $('#confirmInvite').hide()

Template.invites.events =
  "click #invite": (e) ->
    e.preventDefault()
    $('#resetInvite').trigger('click')
    memberSelect = $('#members-to-invite-select')
    memberSelect.show()

  "click #revokeInvite": (e) ->
    e.preventDefault()
    $('#resetInvite').trigger('click')
    memberSelect = $('#members-to-invite-select')
    memberSelect.show()

  "click #resetInvite": (e) ->
    memberSelect = $('#members-to-invite-select')
    e.preventDefault()
    memberSelect.children().filter(":selected").removeAttr("selected")
    memberSelect.hide()
    $('#confirmInvite').hide()

  "click #confirmInvite": (e) ->
    e.preventDefault()
    id = Session.get("document")
    userEmails = $("#members-to-invite-select").val() || []
    return unless userEmails.length > 0

    switch $("#inviteControls .active").data("value")
     when 'send'
      SendInviteToUsers(id, userEmails)
      Session.set('status', 'Invitations sent.')
     when 'revoke'
      RevokeInviteFromUsers(id, userEmails)
      Session.set('status', 'Invitations revoked.')
     else
      return

    Session.set('affectedMembers', userEmails)
    Deps.flush()
    $("#invitesModal").modal('show')
    #Session.set('status', null)
    #Session.set('affectedMembers', null)

    $(@).removeClass('btn-warning btn-danger')
    $(@).hide()

  "change #members-to-invite-select": (e) ->
    e.preventDefault()
    confirmButton = $('#confirmInvite')

    confirmButton.removeClass('btn-warning btn-danger')
    switch $("#inviteControls .active").data("value")
      when 'send' then confirmButton.addClass('btn-warning')
      when 'revoke' then confirmButton.addClass('btn-danger')

    confirmButton.slideDown()
