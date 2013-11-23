Meteor.publish 'documents', ->
    users = [@userId]
    return Documents.find({$or: [{userId: users[0]}, {invitedUsers: {$in: users}}]})

Meteor.publish 'users', ->
    return Meteor.users.find({})

# 