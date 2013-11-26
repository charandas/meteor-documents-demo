userIdsByEmail = (emails) ->
    result = []
    users = Meteor.users.find({"emails.0.address": {$in: emails}}).fetch()
    users.forEach (user) ->
        result.push(user._id)

    return result

@UserEmailsById = (ids) ->
    result = []
    users = Meteor.users.find({"_id": {$in: ids}}).fetch()
    users.forEach (user) ->
        result.push(user.emails[0].address)
    return result

@UserEmailById = (id) ->
    return "" unless id
    user = Meteor.users.findOne({_id: id})
    return user.emails[0].address

@SendInviteToUsers = (id, userEmails) ->
    if userEmails.length > 0
      Documents.update({_id: id}, {$addToSet: {invitedUsers: {$each: userIdsByEmail(userEmails)}}})

@RevokeInviteFromUsers = (id, userEmails) ->
    if userEmails.length > 0
      Documents.update({_id: id}, {$addToSet: {revokePending: {$each: userIdsByEmail(userEmails)}}})