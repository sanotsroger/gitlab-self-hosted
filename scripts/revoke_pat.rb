user = User.find_by_username('root')
token = user&.personal_access_tokens&.find_by(name: 'runner-bootstrap')
if token
  token.revoke!
  puts 'REVOKED'
else
  puts 'NOT_FOUND'
end