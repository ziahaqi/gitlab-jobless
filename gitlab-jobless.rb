require 'rest-client'
require 'json'

API_TOKEN = ENV['GITLAB_API_TOKEN'] #gitlab api token
PROJECT_ID = ENV['GITLAB_PROJECT_ID'] #' gitlab project id
PER_PAGE = '100'
BASE_URL = "https://gitlab.com/api" # gitlab api base url

#
# Get jobs information
#
def get_job_info(page)
  job_api = "#{BASE_URL}/v4/projects/#{PROJECT_ID}/jobs?page=#{page}&per_page=#{PER_PAGE}"
  begin
    response = RestClient::Request.new(
        :method => :get,
        :url => job_api,
        :verify_ssl => false,
        :headers => {"PRIVATE-TOKEN" => API_TOKEN}
    ).execute

    response.headers

  rescue RestClient::ExceptionWithResponse => err
    puts "jobs info error: #{err.response}"
    return nil
  end
end

#
# get jobs data from gitlabs
#
def get_jobs(from, to)

  job_info = get_job_info(from)
  total_page = job_info[:x_total_pages].to_i
  new_to = (to == nil || to < total_page) ? to : total_page
  puts ">> total page : " + total_page.to_s

  jobs = []
  (from..new_to).each do |page|
    job_api = "#{BASE_URL}/v4/projects/#{PROJECT_ID}/jobs?page=#{page}&per_page=#{PER_PAGE}"
    puts ">>start:page:" + page.to_s

    begin
      response = RestClient::Request.new(
          :method => :get,
          :url => job_api,
          :verify_ssl => false,
          :headers => {"PRIVATE-TOKEN" => API_TOKEN}
      ).execute

      if response != nil && response.code == 200
        res = JSON.parse(response.to_str)
        jobs += res
      end

    rescue RestClient::ExceptionWithResponse => err
      puts "jobs error: #{err.response}"
    end
  end

  jobs
end

#
# filter jobs id if have artifacts
#
def filter_jobs_id_by_artifacts(jobs)
  job_ids = []
  jobs.each do |job|
    if job['artifacts_file'] && job['artifacts_file']['filename']
      puts "artifact found for job #{job['id']}"
      job_ids << job['id']
    end
  end

  job_ids
end

#
# remove jobs  artifacts by job Ids
#
def remove_artifacts(job_ids)

  job_ids.each do |id|
    api_url = "#{BASE_URL}/v4/projects/#{PROJECT_ID}/jobs/#{id}/artifacts"

    begin
      response = RestClient::Request.new(
          :method => :delete,
          :url => api_url,
          :verify_ssl => false,
          :headers => {"PRIVATE-TOKEN" => API_TOKEN}
      ).execute

      if response != nil && response.code == 204
        puts "delete job artifacts #{id} => success"
      else
        puts "delete job artifacts #{id} => failed"
      end

    rescue RestClient::ExceptionWithResponse => err
      puts "delete job artifacts #{id} => error"
    end
  end

end

#
# remove jobs by jobs Ids
#
def remove_jobs(job_ids)

  job_ids.each do |id|
    api_url = "#{BASE_URL}/v4/projects/#{PROJECT_ID}/jobs/#{id}/erase"

    begin
      response = RestClient::Request.new(
          :method => :post,
          :url => api_url,
          :verify_ssl => false,
          :headers => {"PRIVATE-TOKEN" => API_TOKEN}
      ).execute

      if response != nil && response.code == 204
        puts "delete job #{id} => success"
      else
        puts "delete job #{id} => failed"
      end

    rescue RestClient::ExceptionWithResponse => err
      puts "delete job artifacts #{id} => error"
    end

  end

end

def main
  jobs = get_jobs(2, 10)
  puts ">>total jobs : " + jobs.size.to_s
  job_ids = filter_jobs_id_by_artifacts(jobs)
  remove_artifacts(job_ids) #use this method to remove artifacts
  # remove_jobs(job_ids) #use this method to remove jobs

end

main
