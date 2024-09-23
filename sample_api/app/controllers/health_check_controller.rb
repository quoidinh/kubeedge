class HealthCheckController < ApplicationController
  def healthcheck
    output = {'message' => 'alive'}.to_json
    render :json => output
  end
end
