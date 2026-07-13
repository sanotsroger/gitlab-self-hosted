begin
  user = User.find_by_username('root')
  raise 'Usuário root não encontrado' if user.nil?

  token = user.personal_access_tokens.find_by(name: 'runner-bootstrap')

  if token.nil?
    token = user.personal_access_tokens.create!(
      name: 'runner-bootstrap',
      scopes: ['api'],
      expires_at: 1.day.from_now
    )
    plain = token.token
    if plain.nil?
      plain = PersonalAccessToken.generate
      token.set_token(plain)
      token.save!(validate: false)
    end
  else
    plain = token.token
  end

  puts 'PAT_MARKER_START'
  puts plain
  puts 'PAT_MARKER_END'
rescue => e
  puts 'PAT_ERROR_START'
  puts "#{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  puts 'PAT_ERROR_END'
end