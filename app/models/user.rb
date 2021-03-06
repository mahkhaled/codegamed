class User < ActiveRecord::Base
  has_many :user_badges
  has_many :badges ,through: :user_badges
  has_many :passed_levels
  has_many :levels, through: :passed_levels
  has_many :passed_missions
  has_many :missions, through: :passed_missions
  after_create :open_first_level_and_mission#,:facebook_friends_save

  #
  has_many :friendships
    has_many :received_friendships, class_name: "Friendship", foreign_key: "friend_id"
    has_many :active_friends, -> { where(friendships: { accepted: true}) }, through: :friendships, source: :friend
    has_many :received_friends, -> { where(friendships: { accepted: true}) }, through: :received_friendships, source: :user
    has_many :pending_friends, -> { where(friendships: { accepted: false}) }, through: :friendships, source: :friend
    has_many :requested_friendships, -> { where(friendships: { accepted: false}) }, through: :received_friendships, source: :user

    # to call all your friends

    def friends
      active_friends | received_friends
    end

# to call your pending sent or received

    def pending
        pending_friends | requested_friendships
    end

    def all_friendships
        pending_friends | requested_friendships| active_friends | received_friends
    end

  #
# Check user existance in db and save new users 
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.image_url = auth.info.image
      user.email=auth.info.email
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.total_score=0
      user.save!
    end
  end
  def raise_score(mission)
    passed_mission=self.passed_missions.where(:mission_id => mission.id).first
    if passed_mission.passed_at.blank?
    User.update(self, "total_score" => self.total_score + mission.score)
    passed_mission.passed_at=Time.now
      passed_mission.save!
    end
  end
  

  private
  def open_first_level_and_mission
    PassedLevel.open_new_level(self.id,1)
    PassedMission.open_new_mission(self.id,1,(PassedLevel.last_level self).id)
  end

  # def facebook_friends_save
  #  Friendship.facebook_friends_save(self)
  # end

end
