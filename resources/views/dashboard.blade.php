<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard </title>
  @vite('resources/css/app.css')
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body class="bg-gray-100 font-sans antialiased">

  <!-- Sidebar + Navbar Container -->
  <div class="flex h-screen">

    <!-- Sidebar -->
    <aside class="w-64 bg-white shadow-md flex flex-col">
      <div class="p-6 flex items-center space-x-3 border-b">
        <img src="{{ asset('images/team_logo.png') }}" alt="Logo" class="h-10 w-10 rounded-full">
        <h1 class="text-lg font-semibold text-gray-700">CodeSprout</h1>
      </div>

      <nav class="flex-1 p-4 space-y-2 text-gray-600">
        <a href="#" class="flex items-center space-x-3 p-2 rounded-lg hover:bg-blue-100 text-blue-700 font-medium">
          <i class="fa-solid fa-house"></i><span>Dashboard</span>
        </a>
        <a href="{{ route('pdf.upload.form') }}" class="flex items-center space-x-3 p-2 rounded-lg hover:bg-blue-50">
          <i class="fa-solid fa-book"></i><span>Past Year Questions</span>
        </a>


        <a href="{{ route('mcq.create') }}" class="flex items-center space-x-3 p-2 rounded-lg hover:bg-blue-100">
          <i class="fa-solid fa-brain"></i><span>MCQ Exercises</span>
        </a>


        </a>
        <a href="#" class="flex items-center space-x-3 p-2 rounded-lg hover:bg-blue-50">
          <i class="fa-solid fa-comments"></i><span>Communication</span>
        </a>
        <a href="#" class="flex items-center space-x-3 p-2 rounded-lg hover:bg-blue-50">
          <i class="fa-solid fa-chart-line"></i><span>Performance</span>
        </a>
      </nav>

      <div class="border-t p-4">
        <p class="text-xs text-gray-400">© {{ date('Y') }} SMK </p>
      </div>
    </aside>

    <!-- Main Dashboard -->
    <main class="flex-1 flex flex-col">

      <!-- Top Navbar -->
      <header class="bg-white shadow flex justify-between items-center px-6 py-4 border-b">
        <div>
          <h2 class="text-xl font-semibold text-gray-800">Dashboard Overview</h2>
          <p class="text-sm text-gray-500">Welcome to CodeSprout</p>
        </div>

        <div class="flex items-center space-x-4">
          <!-- Notification -->
          <button class="relative hover:text-blue-600">
            <i class="fa-solid fa-bell text-gray-600 text-lg"></i>
            <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs px-1 rounded-full">3</span>
          </button>

          <!-- Profile Dropdown -->
          <div class="relative group">
            <button class="flex items-center space-x-2 focus:outline-none">
              <img src="{{ asset('images/profile_placeholder.png') }}" class="h-8 w-8 rounded-full border border-gray-300">
              <span class="text-sm text-gray-700 font-medium">Student</span>
              <i class="fa-solid fa-chevron-down text-xs text-gray-500"></i>
            </button>
            <div class="absolute right-0 mt-2 bg-white border rounded-lg shadow-lg hidden group-hover:block w-40">
              <a href="#" class="block px-4 py-2 text-gray-700 text-sm hover:bg-gray-100">View Profile</a>
              <a href="#" class="block px-4 py-2 text-gray-700 text-sm hover:bg-gray-100">Settings</a>
              <a href="#" class="block px-4 py-2 text-red-600 text-sm hover:bg-gray-100">Logout</a>
            </div>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <section class="flex-1 p-6 overflow-y-auto">

        <!-- Top Stat Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <div class="bg-white shadow rounded-xl p-5 border-l-4 border-blue-500">
            <p class="text-sm text-gray-500 font-medium">MCQ Attempted</p>
            <h3 class="text-2xl font-semibold text-gray-800 mt-2">12/20</h3>
          </div>
          <div class="bg-white shadow rounded-xl p-5 border-l-4 border-green-500">
            <p class="text-sm text-gray-500 font-medium">Past Year Papers</p>
            <h3 class="text-2xl font-semibold text-gray-800 mt-2">8</h3>
          </div>
          <div class="bg-white shadow rounded-xl p-5 border-l-4 border-yellow-500">
            <p class="text-sm text-gray-500 font-medium">Group Chats Joined</p>
            <h3 class="text-2xl font-semibold text-gray-800 mt-2">3</h3>
          </div>
          <div class="bg-white shadow rounded-xl p-5 border-l-4 border-red-500">
            <p class="text-sm text-gray-500 font-medium">Notifications</p>
            <h3 class="text-2xl font-semibold text-gray-800 mt-2">5</h3>
          </div>
        </div>

        <!-- Charts Section -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div class="bg-white p-5 rounded-xl shadow">
            <h4 class="text-lg font-semibold text-gray-800 mb-4">Performance Overview</h4>
            <canvas id="performanceChart" height="180"></canvas>
          </div>

          <div class="bg-white p-5 rounded-xl shadow">
            <h4 class="text-lg font-semibold text-gray-800 mb-4">Progress Summary</h4>
            <canvas id="progressChart" height="180"></canvas>
          </div>
        </div>
      </section>
    </main>
  </div>

  <!-- Font Awesome -->
  <script src="https://kit.fontawesome.com/a2e0b6c4ef.js" crossorigin="anonymous"></script>

  <!-- Chart JS -->
  <script>
    const ctx1 = document.getElementById('performanceChart');
    new Chart(ctx1, {
      type: 'line',
      data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [{
          label: 'Performance',
          data: [10, 20, 15, 25, 30, 40],
          borderColor: '#2563eb',
          backgroundColor: 'rgba(37,99,235,0.1)',
          tension: 0.4,
          fill: true
        }]
      },
      options: { responsive: true, plugins: { legend: { display: false } } }
    });

    const ctx2 = document.getElementById('progressChart');
    new Chart(ctx2, {
      type: 'bar',
      data: {
        labels: ['MCQ', 'Past Papers', 'Group', 'Tasks'],
        datasets: [{
          label: 'Completed',
          data: [70, 50, 30, 90],
          backgroundColor: ['#3b82f6','#10b981','#f59e0b','#ef4444']
        }]
      },
      options: { responsive: true, plugins: { legend: { display: false } } }
    });

  </script>
</body>
</html>
