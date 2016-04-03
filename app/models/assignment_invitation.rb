class AssignmentInvitation < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  update_index('stafftools#assignment_invitation') { self }

  has_one :organization, through: :assignment

  belongs_to :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  def redeem_for(invitee, repo_name_suffix = nil)
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      return assignment_repo if assignment_repo.present?
    end
    create_assignment(repo_name_suffix)
  end

  def create_assignment(repo_name_suffix)
    assignment_repo = AssignmentRepo.find_or_initialize_by(assignment: assignment, user: invitee)
    if assignment_repo.github_repository && repo_name_suffix.nil?
      assignment_repo.add_user_as_collaborator
    else
      assignment_repo.setup_github_repository(repo_name_suffix)
    end
    assignment_repo.save
  end

  def title
    assignment.title
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
