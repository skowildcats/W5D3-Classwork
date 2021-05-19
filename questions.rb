require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end

class Users
  attr_reader :id, :fname, :lname
  def self.find_by_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM users WHERE id = ?
    SQL
    
    Users.new(options[0])
  end

  def self.find_by_name(fname, lname)
    options = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT * FROM users WHERE fname = ? AND lname = ?
    SQL
    
    Users.new(options[0])
  end

  def authored_questions
    Questions.find_by_author_id(@id)
  end

  def authored_replies
    Replies.find_by_user_id(@id)
  end


  def followed_questions
    QuestionsFollows.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionsLikes.liked_questions_for_user_id(@id)
  end

  def average_karma
    all_questions = self.authored_questions
    total_likes = 0
    all_questions.each do |question|
      total_likes += question.num_likes
    end
    return 0 if all_questions.length == 0
    total_likes * (1.0) / all_questions.length
  end

  def save
    if @id
    QuestionsDatabase.instance.execute(<<-SQL, @id, @fname, @lname)
      UPDATE users SET fname = ? 
    SQL

  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
end

class Questions
  def self.find_by_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM questions WHERE id = ?
    SQL
    
    Questions.new(options[0])
  end

  def self.find_by_author_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM questions WHERE users_id = ?
    SQL
    
    options.map {|question| Questions.new(question)}
  end

  def author 
    Users.find_by_id(@users_id)
  end

  def replies
    Replies.find_by_question_id(@id)
  end

  def followers
    QuestionsFollows.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionsFollows.most_followed_questions(n)
  end

  def likers
    QuestionsLikes.likers_for_question_id(@id)
  end

  def num_likes
    QuestionsLikes.num_likes_for_question_id(@id)
  end

  def self.most_liked(n)
    QuestionsLikes.most_liked_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @users_id = options['users_id']
  end
end

class QuestionsFollows
  def self.find_by_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM questions_follows WHERE id = ?
    SQL
    
    QuestionsFollows.new(options[0])
  end

  def self.followers_for_question_id(questions_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
      SELECT users.id, fname, lname
      FROM users JOIN questions_follows ON users.id = questions_follows.users_id
      WHERE questions_id = ?
    SQL
    followers.map {|follower| Users.new(follower)}
  end

  def self.followed_questions_for_user_id(users_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, users_id)
      SELECT questions.id, title, body, questions.users_id
      FROM questions JOIN questions_follows ON questions.id = questions_follows.questions_id
      WHERE questions_follows.users_id = ?
    SQL
    questions.map {|question| Questions.new(question)}
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT questions.id, title, body, questions_follows.users_id
      FROM questions JOIN questions_follows ON questions.id = questions_follows.questions_id
      GROUP BY questions_id
      ORDER BY COUNT(questions_follows.users_id) DESC
      LIMIT ?
    SQL
    questions.map {|question| Questions.new(question)}
  end

  def initialize(options)
    @id = options['id']
    @users_id = options['users_id']
    @questions_id = options['questions_id']
  end
end

class Replies
  def self.find_by_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM replies WHERE id = ?
    SQL
    
    Replies.new(options[0])
  end

  def self.find_by_user_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM replies WHERE users_id = ?
    SQL
    
    options.map {|reply| Replies.new(reply)}
  end

  def self.find_by_question_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM replies WHERE questions_id = ?
    SQL
    
    options.map {|reply| Replies.new(reply)}
  end

  def author 
    Users.find_by_id(@users_id)
  end

  def question
    Questions.find_by_id(@questions_id)
  end

  def parent_reply
    raise 'No parent' if @replies_id == 0
    Replies.find_by_id(@replies_id)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT * FROM replies WHERE replies_id = ?
    SQL
    children.map {|child| Replies.new(child)}
    
  end

  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
    @body = options['body']
    @replies_id = options['replies_id']
  end
end

class QuestionsLikes
  def self.find_by_id(id)
    options = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT * FROM questions_likes WHERE id = ?
    SQL
    
    QuestionsLikes.new(options[0])
  end

  def self.likers_for_question_id(questions_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
      SELECT users.id, fname, lname
      FROM users JOIN questions_likes ON users.id = questions_likes.users_id
      WHERE questions_id = ?
    SQL
    likers.map {|like| Users.new(like)}
  end

  def self.num_likes_for_question_id(questions_id)
    num_likes = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
      SELECT COUNT(*) AS num_likes
      FROM users JOIN questions_likes ON users.id = questions_likes.users_id
      WHERE questions_id = ?
    SQL
    return num_likes.first['num_likes']
  end

  def self.liked_questions_for_user_id(users_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, users_id)
      SELECT questions.id, title, body, questions.users_id
      FROM questions JOIN questions_likes ON questions.id = questions_likes.questions_id
      WHERE questions_likes.users_id = ?
    SQL
    questions.map {|question| Questions.new(question)}
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT questions.id, title, body, questions.users_id
      FROM questions JOIN questions_likes ON questions.id = questions_likes.questions_id
      GROUP BY questions_id
      ORDER BY COUNT(questions_likes.users_id) DESC
      LIMIT ?
    SQL
    questions.map {|question| Questions.new(question)}
  end

  def initialize(options)
    @id = options['id']
    @users_id = options['users_id']
    @questions_id = options['questions_id']
  end
end