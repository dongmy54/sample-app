class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token 
                # 定义三个虚拟属性
  before_save   :email_downcase
  before_create :create_activation_digest
  
  validates :name, presence: true, length: { maximum: 50}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255},
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  scope :activated, -> { where("activated = ?", true)}

  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)      
  end   # 作用：将字符串转换为摘要
  
  def User.new_token
    SecureRandom.urlsafe_base64
  end   # 作用： 生成token值

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticate?(attribute,token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def activate
    update(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update!(:reset_digest  => User.digest(reset_token),
           :reset_send_at => Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now!
  end

  def password_reset_expired?
    reset_send_at < 2.hours.ago    
  end

  private

    def email_downcase
      email.downcase!
    end

    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
    
end
