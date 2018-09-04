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

# id INTEGER PRIMARY KEY,
# title VARCHAR(255) NOT NULL,
# body TEXT NOT NULL,
# author_id INTEGER NOT NULL,

class Question
  attr_accessor :title, :body
  attr_reader :author_id
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map{ |datum| Question.new(datum)}
  end
  
  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL,id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    Question.new(question.first)
  end
  
  def self.find_by_author_id(author_id)
    question = QuestionsDatabase.instance.execute(<<-SQL,author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
    SQL
    Question.new(question.first)
  end
  
  def author
    Question.find_by_author_id(@author_id)
  end
  
  def replies
    Reply.find_by_question_id(@id)
  end
  
  def followers
    QuestionFollow.followers_for_question_id(@id)
  end
  
end

# CREATE TABLE users (
#   id INTEGER PRIMARY KEY,
#   fname VARCHAR(255) NOT NULL,
#   lname VARCHAR(255) NOT NULL

class User
  attr_accessor :fname, :lname
  
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map{ |datum| User.new(datum)}
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL,id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    User.new(question.first)
  end


  def self.find_by_name(fname, lname)
    question = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ?
    AND
      lname = ?
    SQL
    User.new(question.first)
  end
  
  def authored_questions
    Question.find_by_author_id(@id)
  end 
  
  def authored_replies
    Reply.find_by_user_id(@id)
  end
    
  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end
    
end

# id INTEGER PRIMARY KEY,
# question_id INTEGER NOT NULL,
# parent_reply_id INTEGER,
# author_id INTEGER NOT NULL,
# body TEXT NOT NULL,

class Reply
  attr_accessor :fname, :lname
  
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map{ |datum| Reply.new(datum)}
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    Reply.new(question.first)
  end
  
  def self.find_by_user_id(author_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      replies
    WHERE
      author_id = ?
    SQL
    Reply.new(question.first)
  end

  def self.find_by_question_id(question_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
    SQL
    Reply.new(question.first)
  end

  def author
    QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE author_id = #{@author_id}")
  end
  
  def question
    QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = #{@question_id}")
  end
  
  def parent_reply
    QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE parent_reply_id = #{@parent_reply_id}")
  end
  
  def child_replies
    QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE parent_reply_id = #{@id}")
  end
end

# id INTEGER PRIMARY KEY,
# user_id INTEGER NOT NULL,
# question_id INTEGER NOT NULL,

class QuestionFollow
  attr_accessor :user_id, :question_id
  
  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map{ |datum| QuestionFollow.new(datum)}
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      id = ?
    SQL
    QuestionFollow.new(question.first)
  end
  
  def self.followers_for_question_id(question_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
    users.*
    FROM
      question_follows
    JOIN
      users
    on users.id = question_follows.user_id
    where question_id = ?
    SQL
    
    question.map{|question| User.new(question)}
  end
  
  def self.followed_questions_for_user_id(user_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
    questions.*
    FROM
      question_follows
    JOIN
      questions
    on questions.id = question_follows.question_id
    where user_id = ?
    SQL
    
    question.map{|question| User.new(question)}
  end

  def self.most_followed_questions(n)
    question = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT questions.*, count(*) as num_likes
    FROM
      question_follows
    JOIN
      questions
    on questions.id = question_follows.question_id
    order by num_likes DESC
    limit ?
    SQL
    
    question.map{|question| User.new(question)}
  end


end




  