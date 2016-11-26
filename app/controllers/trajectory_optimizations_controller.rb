class TrajectoryOptimizationsController < TrajectoryOptimizationController
  def index
    @optimizations = TrajectoryOptimization.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @optimizations.map{|optimization| objectify_optimization(optimization)} }
    end
  end

  def show
    @optimization = TrajectoryOptimization.find(params[:id])
    @optimization.simulator_log_list = objectify_json(@optimization.simulator_log_list).map do |states|
      refine_states(states)
    end.to_json

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: objectify_optimization(@optimization) }
    end
  end

  def destroy
    @optimization = TrajectoryOptimization.find(params[:id])
    @optimization.destroy

    respond_to do |format|
      format.html { redirect_to(trajectory_optimizations_url) }
      format.json { head :ok }
    end
  end

  def duplicate
    @optimization = TrajectoryOptimization.find(params[:id]).dup

    respond_to do |format|
      if @optimization.save
        flash[:notice] = 'optimization was successfully duplicated.'
        format.html { redirect_to(@optimization) }
        format.json { render json: objectify_optimization(@optimization), status: :created, location: @optimization }
      else
        format.html { redirect_to :back }
        format.json { render json: @optimization.errors, status: :unprocessable_entity }
      end
    end
  end

  def iteration_show
    @optimization = TrajectoryOptimization.find(params[:id])
    @iteration_id = params[:iteration_id].to_i

    @refined_reference = refine_states(objectify_json(@optimization.episode.states)).to_json
    @refined_response  = refine_states(objectify_json(@optimization.simulator_log_list)[@iteration_id]).to_json

    respond_to do |format|
      format.html # iteration_show.html.erb
      format.json { render json: objectify_optimization(@optimization) }
    end
  end

  def iteration_render3d
    @optimization = TrajectoryOptimization.find(params[:id])
    @iteration_id = params[:iteration_id].to_i

    @refined_reference = refine_states(objectify_json(@optimization.episode.states)).to_json
    @refined_response  = refine_states(objectify_json(@optimization.simulator_log_list)[@iteration_id]).to_json
    @differences = differences_between(objectify_json(@refined_reference), objectify_json(@refined_response)).map do |difference|
      rx, ry, rz = matrix_to_euler(difference[:rotation])
      {
        :t => difference[:t],
        :x => difference[:position].x,
        :y => difference[:position].y,
        :z => difference[:position].z,
        :rx => rx,
        :ry => ry,
        :rz => rz,
      }
    end.to_json

    respond_to do |format|
      format.html # iteration_render3d.html.erb
      format.json { render json: objectify_optimization(@optimization) }
    end
  end
end
