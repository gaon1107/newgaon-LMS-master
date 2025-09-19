import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Button,
  TextField,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Avatar,
  FormControlLabel,
  Checkbox,
  Divider,
  Alert
} from '@mui/material'
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon
} from '@mui/icons-material'

const StudentPage = () => {
  const [students, setStudents] = useState([])
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedClass, setSelectedClass] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingStudent, setEditingStudent] = useState(null)
  const [loading, setLoading] = useState(false)

  const [formData, setFormData] = useState({
    name: '',
    school: '',
    grade: '',
    department: '',
    phone: '',
    parentPhone: '',
    email: '',
    class: '',
    birthDate: '',
    address: '',
    notes: '',
    // 추가된 필드들
    selectedClass: '',
    classFee: 0,
    paymentDueDate: '',
    sendPaymentNotification: true,
    profileImage: null
  })

  // 임시 데이터
  const mockStudents = [
    {
      id: 1,
      name: '김철수',
      school: '가온 중학교',
      grade: '3',
      department: '수학과',
      phone: '010-1111-2222',
      parentPhone: '010-9999-8888',
      email: 'parent1@example.com',
      class: '수학 A반',
      birthDate: '2010-03-15',
      address: '서울시 강남구',
      notes: '수학에 관심이 많음',
      selectedClass: 'math_a',
      classFee: 150000,
      paymentDueDate: '2025-01-25',
      sendPaymentNotification: true,
      profileImage: null
    },
    {
      id: 2,
      name: '이영희',
      school: '가온 고등학교',
      grade: '1',
      department: '영어과',
      phone: '010-2222-3333',
      parentPhone: '010-8888-7777',
      email: 'parent2@example.com',
      class: '영어 B반',
      birthDate: '2011-07-22',
      address: '서울시 서초구',
      notes: '영어 회화 실력 우수',
      selectedClass: 'english_b',
      classFee: 110000,
      paymentDueDate: '2025-01-30',
      sendPaymentNotification: true,
      profileImage: null
    }
  ]

  const mockClasses = [
    { id: '', name: '전체' },
    { id: 'math_a', name: '수학 A반', fee: 150000 },
    { id: 'math_b', name: '수학 B반', fee: 120000 },
    { id: 'english_a', name: '영어 A반', fee: 130000 },
    { id: 'english_b', name: '영어 B반', fee: 110000 },
    { id: 'science', name: '과학 C반', fee: 140000 },
    { id: 'coding', name: '코딩반', fee: 180000 }
  ]

  const mockDepartments = [
    { id: 'math', name: '수학과' },
    { id: 'english', name: '영어과' },
    { id: 'science', name: '과학과' },
    { id: 'korean', name: '국어과' },
    { id: 'social', name: '사회과' },
    { id: 'art', name: '예체과' }
  ]

  useEffect(() => {
    loadStudents()
  }, [])

  const loadStudents = async () => {
    setLoading(true)
    try {
      setTimeout(() => {
        setStudents(mockStudents)
        setLoading(false)
      }, 500)
    } catch (error) {
      console.error('학생 데이터 로딩 실패:', error)
      setLoading(false)
    }
  }

  const resetForm = () => {
    setFormData({
      name: '',
      school: '',
      grade: '',
      department: '',
      phone: '',
      parentPhone: '',
      email: '',
      class: '',
      birthDate: '',
      address: '',
      notes: '',
      selectedClass: '',
      classFee: 0,
      paymentDueDate: '',
      sendPaymentNotification: true,
      profileImage: null
    })
  }

  const handleOpenDialog = (student = null) => {
    if (student) {
      setEditingStudent(student)
      setFormData(student)
    } else {
      setEditingStudent(null)
      resetForm()
    }
    setDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setDialogOpen(false)
    setEditingStudent(null)
    resetForm()
  }

  const handleInputChange = (field) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value

    setFormData(prev => {
      const newData = {
        ...prev,
        [field]: value
      }

      // 강의 선택 시 비용 자동 설정
      if (field === 'selectedClass') {
        const selectedClassInfo = mockClasses.find(c => c.id === value)
        if (selectedClassInfo && selectedClassInfo.fee) {
          newData.classFee = selectedClassInfo.fee
          newData.class = selectedClassInfo.name
        } else {
          newData.classFee = 0
        }
      }

      return newData
    })
  }

  const handleImageUpload = (event) => {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        setFormData(prev => ({
          ...prev,
          profileImage: e.target.result
        }))
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    
    try {
      if (editingStudent) {
        console.log('학생 수정:', formData)
        setStudents(prev => prev.map(student => 
          student.id === editingStudent.id 
            ? { ...formData, id: editingStudent.id }
            : student
        ))
      } else {
        console.log('학생 추가:', formData)
        const newStudent = {
          ...formData,
          id: Date.now()
        }
        setStudents(prev => [newStudent, ...prev])
      }
      
      handleCloseDialog()
    } catch (error) {
      console.error('학생 저장 실패:', error)
    }
  }

  const handleDelete = async (studentId) => {
    if (window.confirm('정말 삭제하시겠습니까?')) {
      try {
        console.log('학생 삭제:', studentId)
        setStudents(prev => prev.filter(student => student.id !== studentId))
      } catch (error) {
        console.error('학생 삭제 실패:', error)
      }
    }
  }

  const filteredStudents = students.filter(student =>
    student.name.toLowerCase().includes(searchTerm.toLowerCase()) &&
    (selectedClass === '' || student.class === mockClasses.find(c => c.id === selectedClass)?.name)
  )

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          학생 관리
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          학생 추가
        </Button>
      </Box>

      {/* 검색 및 필터 */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                placeholder="학생 이름 검색"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControl fullWidth>
                <InputLabel>반 필터</InputLabel>
                <Select
                  value={selectedClass}
                  onChange={(e) => setSelectedClass(e.target.value)}
                  label="반 필터"
                >
                  {mockClasses.map((cls) => (
                    <MenuItem key={cls.id} value={cls.id}>
                      {cls.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={2}>
              <Typography variant="body2" color="text.secondary">
                총 {filteredStudents.length}명
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* 학생 목록 테이블 */}
      <Card>
        <CardContent>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>프로필</TableCell>
                  <TableCell>이름</TableCell>
                  <TableCell>학교/학년</TableCell>
                  <TableCell>학과</TableCell>
                  <TableCell>반</TableCell>
                  <TableCell>수강료</TableCell>
                  <TableCell>연락처</TableCell>
                  <TableCell>학부모 연락처</TableCell>
                  <TableCell>결제일</TableCell>
                  <TableCell>관리</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={10} align="center">
                      데이터를 불러오는 중...
                    </TableCell>
                  </TableRow>
                ) : filteredStudents.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={10} align="center">
                      학생 데이터가 없습니다.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredStudents.map((student) => (
                    <TableRow key={student.id}>
                      <TableCell>
                        {student.profileImage ? (
                          <Avatar
                            src={student.profileImage}
                            sx={{ width: 40, height: 40 }}
                          />
                        ) : (
                          <Avatar sx={{ width: 40, height: 40 }}>
                            {student.name.charAt(0)}
                          </Avatar>
                        )}
                      </TableCell>
                      <TableCell>{student.name}</TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {student.school}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {student.grade}학년
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip label={student.department} size="small" color="secondary" />
                      </TableCell>
                      <TableCell>
                        <Chip label={student.class} size="small" />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="bold" color="primary">
                          {student.classFee ? `${student.classFee.toLocaleString()}원` : '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>{student.phone}</TableCell>
                      <TableCell>{student.parentPhone}</TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {student.paymentDueDate ? `매월 ${student.paymentDueDate.split('-')[2]}일` : '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <IconButton
                          size="small"
                          onClick={() => handleOpenDialog(student)}
                          sx={{ mr: 1 }}
                        >
                          <EditIcon />
                        </IconButton>
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => handleDelete(student.id)}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* 학생 추가/수정 다이얼로그 */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingStudent ? '학생 정보 수정' : '새 학생 추가'}
        </DialogTitle>
        <DialogContent>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 1 }}>
            <Grid container spacing={2}>
              {/* 좌측: 학생 정보 */}
              <Grid item xs={12} md={8}>
                <Typography variant="h6" gutterBottom color="primary">
                  학생 정보
                </Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="이름 *"
                      value={formData.name}
                      onChange={handleInputChange('name')}
                      required
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학교"
                      value={formData.school}
                      onChange={handleInputChange('school')}
                      placeholder="가온 중학교 3"
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학년"
                      value={formData.grade}
                      onChange={handleInputChange('grade')}
                      placeholder="3"
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth>
                      <InputLabel>학과</InputLabel>
                      <Select
                        value={formData.department}
                        onChange={handleInputChange('department')}
                        label="학과"
                      >
                        {mockDepartments.map((dept) => (
                          <MenuItem key={dept.id} value={dept.name}>
                            {dept.name}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학생 연락처"
                      value={formData.phone}
                      onChange={handleInputChange('phone')}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="학부모 연락처 *"
                      value={formData.parentPhone}
                      onChange={handleInputChange('parentPhone')}
                      required
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="이메일"
                      type="email"
                      value={formData.email}
                      onChange={handleInputChange('email')}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControl fullWidth>
                      <InputLabel>강의 선택 *</InputLabel>
                      <Select
                        value={formData.selectedClass}
                        onChange={handleInputChange('selectedClass')}
                        label="강의 선택 *"
                        required
                      >
                        {mockClasses.filter(c => c.id !== '').map((cls) => (
                          <MenuItem key={cls.id} value={cls.id}>
                            {cls.name} - {cls.fee.toLocaleString()}원
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </Grid>

                  {/* 선택된 강의 비용 표시 */}
                  {formData.selectedClass && formData.classFee > 0 && (
                    <Grid item xs={12}>
                      <Alert severity="info">
                        선택된 강의: <strong>{formData.class}</strong><br/>
                        월 수강료: <strong>{formData.classFee.toLocaleString()}원</strong>
                      </Alert>
                    </Grid>
                  )}

                  {/* 결제 정보 섹션 */}
                  <Grid item xs={12}>
                    <Divider sx={{ my: 2 }}>
                      <Typography variant="h6" color="primary">
                        결제 정보
                      </Typography>
                    </Divider>
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="수강료"
                      value={formData.classFee > 0 ? `${formData.classFee.toLocaleString()}원` : ''}
                      disabled
                      helperText="선택한 강의에 따라 자동 설정됩니다"
                    />
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="결제일 *"
                      type="date"
                      value={formData.paymentDueDate}
                      onChange={handleInputChange('paymentDueDate')}
                      InputLabelProps={{
                        shrink: true,
                      }}
                      required
                      helperText="매월 결제해야 할 날짜를 지정해주세요"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.sendPaymentNotification}
                          onChange={handleInputChange('sendPaymentNotification')}
                          color="primary"
                        />
                      }
                      label="결제 안내 문자 발송 (결제 기한일 전에 알림 문자를 발송합니다)"
                    />
                  </Grid>

                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="생년월일"
                      type="date"
                      value={formData.birthDate}
                      onChange={handleInputChange('birthDate')}
                      InputLabelProps={{
                        shrink: true,
                      }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="주소"
                      value={formData.address}
                      onChange={handleInputChange('address')}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="비고"
                      multiline
                      rows={3}
                      value={formData.notes}
                      onChange={handleInputChange('notes')}
                    />
                  </Grid>
                </Grid>
              </Grid>

              {/* 우측: 학생 사진 */}
              <Grid item xs={12} md={4}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="h6" gutterBottom color="primary">
                    학생 사진
                  </Typography>
                  <Box
                    sx={{
                      width: '200px',
                      height: '250px',
                      border: '2px dashed #ccc',
                      borderRadius: '8px',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      justifyContent: 'center',
                      mx: 'auto',
                      mb: 2,
                      cursor: 'pointer',
                      '&:hover': {
                        borderColor: '#1976d2'
                      }
                    }}
                    onClick={() => document.getElementById('photo-upload').click()}
                  >
                    {formData.profileImage ? (
                      <img
                        src={formData.profileImage}
                        alt="학생 사진"
                        style={{
                          width: '100%',
                          height: '100%',
                          objectFit: 'cover',
                          borderRadius: '6px'
                        }}
                      />
                    ) : (
                      <>
                        <Avatar sx={{ width: 80, height: 80, mb: 2 }}>
                          <Typography variant="h4">📷</Typography>
                        </Avatar>
                        <Typography variant="body2" color="text.secondary">
                          학생 사진을 등록할수 있게<br/>
                          만들어 주고 사진 아이콘을<br/>
                          선택하면 카메라 활성화 또는<br/>
                          이미지 업로드 선택하여 진행 할수 있게 수정
                        </Typography>
                        <Typography variant="body2" color="primary" sx={{ mt: 1 }}>
                          복수로 선택할수 있게 수정
                        </Typography>
                      </>
                    )}
                  </Box>
                  <input
                    id="photo-upload"
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={handleImageUpload}
                  />
                  <Button
                    variant="outlined"
                    onClick={() => document.getElementById('photo-upload').click()}
                    sx={{ mb: 1 }}
                  >
                    사진 선택
                  </Button>
                  {formData.profileImage && (
                    <Button
                      variant="text"
                      color="error"
                      onClick={() => setFormData(prev => ({ ...prev, profileImage: null }))}
                      sx={{ display: 'block', mx: 'auto' }}
                    >
                      사진 삭제
                    </Button>
                  )}
                </Box>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>
            취소
          </Button>
          <Button
            onClick={handleSubmit}
            variant="contained"
            disabled={!formData.name || !formData.parentPhone || !formData.selectedClass || !formData.paymentDueDate}
          >
            {editingStudent ? '수정' : '추가'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default StudentPage
