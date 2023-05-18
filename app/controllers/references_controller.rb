class ReferencesController < ApplicationController
    helper_method :sort_column, :sort_direction

    def index
        @references = Reference.where.not(metadata: nil).order(sort_column + " " + sort_direction)
        @without_metadata = Reference.where(metadata: nil).order("abbr asc")
    end

    private

    def sort_column
        params.include?(:sort) ? params[:sort] : "abbr"
    end

    def sort_direction
        %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end
