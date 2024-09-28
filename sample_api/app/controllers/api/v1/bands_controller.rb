require 'prometheus/client'
require 'prometheus/client/push'
require 'prometheus/client/registry'
class Api::V1::BandsController < ApplicationController
  before_action :set_band, only: [:show, :update, :destroy]

  # GET /bands
  def index

    prometheus = Prometheus::Client.registry
    push = Prometheus::Client::Push.new(job: "my-job", gateway: "http://127.0.0.1:7091") #.replace(prometheus)
    push.basic_auth("admin", "admin") 
    
      # Counter
      http_requests_total = Prometheus::Client::Counter.new(:http_requests_total,docstring:'...' )

      # Summary
      read_latency = Prometheus::Client::Summary.new(:ruby_http_request_duration_seconds,docstring:'...')

      http_requests_total.increment
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      # # some HTTP request code here
      elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      read_latency.observe(elapsed_time)
      Prometheus::Client::Push.new(docstring: '...',labels: [:service, :component],preset_labels: { service: "my_service" },job: "http_requests_total", gateway: "http://192.168.1.28:9090").basic_auth("admin", "admin") 
      Prometheus::Client::Push.new(  docstring: '...',labels: [:service, :component],preset_labels: { service: "my_service" },job: "ruby_http_request_duration_seconds", gateway: "http://192.168.1.28:9090").basic_auth("admin", "admin") 
      # prometheus.register(http_requests_total)
      # prometheus.register(read_latency)

      # # Create a simple my-external-metric metric.
      my-external-metric = Prometheus::Client::Gauge.new(:my-external-metric,docstring: '...')
      # Register my-external-metric with the registry we previously created.
      begin
        prometheus.register(my-external-metric)
     rescue
       puts "registered my-external-metric"
     end
     my-external-metric.increment
      Prometheus::Client::Push.new(docstring: '...',labels: [:service, :component],preset_labels: { service: "my_service" },job: "my-job", gateway: "http://192.168.1.28:9090").basic_auth("admin", "admin") 
      # https://github.com/prometheus/client_ruby
    @bands = Band.all

    render json: @bands
  end

  # GET /bands/1
  def show
    render json: @band
  end

  # POST /bands
  def create
    @band = Band.new(band_params)

    if @band.save
      render json: @band, status: :created, location: @band
    else
      render json: @band.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /bands/1
  def update
    if @band.update(band_params)
      render json: @band
    else
      render json: @band.errors, status: :unprocessable_entity
    end
  end

  # DELETE /bands/1
  def destroy
    @band.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_band
      @band = Band.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def band_params
      params.require(:band).permit(:name)
    end
end
