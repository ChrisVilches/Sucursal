class AppointmentsController < ApplicationController

  include Scheduling

  def schedule_appointment

    ActiveRecord::Base.transaction do

      times = get_times

      if times.has_key? :error
        render :json => times, :status => :bad_request
        return
      end

      # Si no hay ningun error, entonces proceder a realizar el agendamiento

      attention_type_id = params[:attention_type_id].to_i
      yyyy = params[:yyyy].to_i
      mm = params[:mm].to_i
      dd = params[:dd].to_i
      hour = params[:hour].to_i
      minutes = params[:minutes].to_i

      min = (hh * 60) + mm

      # Si el tiempo seleccionado no pertenece al conjunto de tiempos
      # disponibles, o si el conjunto de ejecutivos para ese tiempo es vacio
      # (lo cual no deberia pasar), entonces se arroja error.
      if times.empty? || !(times.has_key? min) || times[min].empty?
        msg = "La hora seleccionada no se encuentra disponible"
        render :json => { :error => msg }, :status => :bad_request
        return
      end

      executive_id = times[min].shuffle.first

      Appointment.new(executive_id: executive_id,
        attention_type_id: attention_type_id,
        time: Time.zone.parse("#{yyyy}-#{mm}-#{dd} #{hour}:#{minutes}:00"),
        client_id: params[:client_id].to_i)

      render :json => { msg: "La hora ha sido correctamente agendada a las #{hour}:#{minutes}" }, :status => :ok
      return

    end

  end

  def get_available_times

    times = get_times

    if times.has_key? :error
      render :json => times, :status => :bad_request
      return
    end

    render :json => { times: times.keys.sort }, :status => :ok

  end

  private

  def get_times
    # Aca se debe implementar una politica de acceso. El usuario debe estar
    # autorizado para ejecutar esta accion. Como aun no se tiene la integracion
    # con el resto del sistema movistar, queda pendiente.

    # Se debe retornar codigo de estado 403 Forbidden o bien 401 Unauthorized.
    # Por mientras, dejo que se pase la ID del cliente por query params, es decir
    # /url?client_id = 123
    # Tambien se deja como Pending en los rspec (pruebas unitarias).

    client_id = params[:client_id].to_i

    # ------------------------------------------

    # Obtengo los parametros de la URL
    branch_office_id = params[:branch_office_id].to_i
    attention_type_id = params[:attention_type_id].to_i

    # Obtengo los parametros del dia
    yyyy = params[:yyyy].to_i
    mm = params[:mm].to_i
    dd = params[:dd].to_i

    # Verifico que el dia formado sea correcto. En caso que no lo sea,
    # se debe arrojar un error.
    begin
      day = Time.zone.parse("#{yyyy}-#{mm}-#{dd}")
    rescue => e
      msg = "La fecha es incorrecta"
      return { :error => msg }
    end



    # Verificar que la fecha sea mayor al limite inferior, el cual
    # corresponde al dia de manana (la hora es el inicio de ese dia 00:00:00).
    # Lo mismo con el dia que comienza en una semana (limite superior).
    range_days = 7
    today = Time.current.beginning_of_day
    tomorrow = today.tomorrow

    max_day = today
    range_days.times { max_day = max_day.next_day }

    if already_has_appointment? client_id
      msg = "No se puede consultar el servicio de agendas porque ya tiene una hora agendada"
      return { :error => msg }
    end

    if day.beginning_of_day < tomorrow
      msg = "Solo se puede pedir citas comenzando desde el día de mañana"
      return { :error => msg }
    end

    if max_day < day.beginning_of_day
      msg = "Solo se puede pedir citas hasta #{range_days} días después comenzando desde el día de mañana"
      return { :error => msg }
    end


    # Obtengo todos los tiempos en donde es posible agendar una hora.
    return get_all_available_appointments(
      day: day.to_date,
      branch_office_id: branch_office_id,
      attention_type_id: attention_type_id)

  end




  def already_has_appointment?(client_id)
    latest_appointment = Appointment.where(client_id: client_id).order("time DESC").first
    return false if latest_appointment.nil?
    today = Time.current.beginning_of_day
    time = latest_appointment.time.beginning_of_day
    return today <= time
  end


end
