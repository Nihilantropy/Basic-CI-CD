# Use the official GitLab Community Edition (CE) image
FROM gitlab/gitlab-ce:latest

# Set environment variables for first-time setup
ENV GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.local'; \
						gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'"

# Expose GitLab required ports
EXPOSE 80 443 22

# Define default startup command
CMD ["/assets/wrapper"]
